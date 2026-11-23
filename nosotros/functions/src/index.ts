/**
 * Servidor de "Nosotros".
 *
 * - createCouple / joinCouple: vinculan a las dos personas con un código.
 * - onStoryWritten: borra la foto anterior cuando se sube una nueva y manda
 *   las notificaciones (story nueva y like).
 * - cleanupExpiredStories: cada 10 minutos borra las stories de más de 24 h.
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getStorage } from "firebase-admin/storage";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { onSchedule } from "firebase-functions/v2/scheduler";

initializeApp();
setGlobalOptions({ maxInstances: 5 });

const db = getFirestore();

function randomCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// ---------------------------------------------------------------------------
// Vinculación
// ---------------------------------------------------------------------------

export const createCouple = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Inicia sesión.");

  const userRef = db.collection("users").doc(uid);
  const user = await userRef.get();
  if (!user.exists) throw new HttpsError("failed-precondition", "Crea tu perfil.");

  const existing = user.get("coupleId") as string | undefined;
  if (existing) {
    const couple = await db.collection("couples").doc(existing).get();
    if (couple.exists) {
      if ((couple.get("members") as string[]).length >= 2) {
        throw new HttpsError("already-exists", "Ya tienes pareja.");
      }
      return { code: couple.get("code") as string };
    }
  }

  // Busca un código libre.
  for (let i = 0; i < 10; i++) {
    const code = randomCode();
    const codeRef = db.collection("codes").doc(code);
    const coupleRef = db.collection("couples").doc();
    const ok = await db.runTransaction(async (tx) => {
      if ((await tx.get(codeRef)).exists) return false;
      tx.set(coupleRef, {
        members: [uid],
        code,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.set(codeRef, { coupleId: coupleRef.id });
      tx.update(userRef, { coupleId: coupleRef.id });
      return true;
    });
    if (ok) return { code };
  }
  throw new HttpsError("internal", "Intenta de nuevo.");
});

export const joinCouple = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Inicia sesión.");
  const code = String(req.data?.code ?? "").trim();
  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Código inválido.");
  }

  const userRef = db.collection("users").doc(uid);
  const codeRef = db.collection("codes").doc(code);

  await db.runTransaction(async (tx) => {
    const [codeSnap, userSnap] = await Promise.all([tx.get(codeRef), tx.get(userRef)]);
    if (!userSnap.exists) throw new HttpsError("failed-precondition", "Crea tu perfil.");
    if (!codeSnap.exists) throw new HttpsError("not-found", "Ese código no existe.");

    const coupleRef = db.collection("couples").doc(codeSnap.get("coupleId"));
    const couple = await tx.get(coupleRef);
    const members = (couple.get("members") as string[] | undefined) ?? [];
    if (members.includes(uid)) {
      throw new HttpsError("invalid-argument", "Ese es tu propio código. Compártelo con tu pareja.");
    }
    if (!couple.exists || members.length >= 2) {
      throw new HttpsError("already-exists", "Esa pareja ya está completa.");
    }

    // Si esta persona había creado su propio código, se descarta.
    const ownCoupleId = userSnap.get("coupleId") as string | undefined;
    if (ownCoupleId && ownCoupleId !== coupleRef.id) {
      const ownRef = db.collection("couples").doc(ownCoupleId);
      const own = await tx.get(ownRef);
      const ownMembers = (own.get("members") as string[] | undefined) ?? [];
      if (own.exists && ownMembers.length >= 2) {
        throw new HttpsError("already-exists", "Ya tienes pareja.");
      }
      if (own.exists) {
        tx.delete(ownRef);
        tx.delete(db.collection("codes").doc(own.get("code")));
      }
    }

    tx.update(coupleRef, { members: FieldValue.arrayUnion(uid) });
    tx.update(userRef, { coupleId: coupleRef.id });
    // La pareja está completa: el código ya no sirve.
    tx.delete(codeRef);
  });
  return { ok: true };
});

// ---------------------------------------------------------------------------
// Stories
// ---------------------------------------------------------------------------

async function deleteFile(path: string | undefined) {
  if (!path) return;
  try {
    await getStorage().bucket().file(path).delete({ ignoreNotFound: true });
  } catch (e) {
    logger.warn("No se pudo borrar", path, e);
  }
}

async function partnerOf(coupleId: string, uid: string): Promise<string | null> {
  const couple = await db.collection("couples").doc(coupleId).get();
  const members = (couple.get("members") as string[] | undefined) ?? [];
  return members.find((m) => m !== uid) ?? null;
}

async function notify(
  uid: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  const userRef = db.collection("users").doc(uid);
  const tokens = ((await userRef.get()).get("fcmTokens") as string[] | undefined) ?? [];
  if (tokens.length === 0) return;

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: { channelId: "stories", sound: "default" },
    },
    apns: {
      payload: { aps: { sound: "default", contentAvailable: true } },
    },
  });

  // Quita los teléfonos que ya no existen (app borrada, sesión cerrada).
  const invalid = res.responses
    .map((r, i) => (r.success ? null : { code: r.error?.code, token: tokens[i] }))
    .filter((x): x is { code: string | undefined; token: string } =>
      !!x &&
      (x.code === "messaging/registration-token-not-registered" ||
        x.code === "messaging/invalid-registration-token"))
    .map((x) => x.token);
  if (invalid.length > 0) {
    await userRef.update({ fcmTokens: FieldValue.arrayRemove(...invalid) });
  }
}

async function nameOf(uid: string): Promise<string> {
  return ((await db.collection("users").doc(uid).get()).get("name") as string) ?? "Tu pareja";
}

export const onStoryWritten = onDocumentWritten(
  "couples/{coupleId}/stories/{ownerUid}",
  async (event) => {
    const { coupleId, ownerUid } = event.params;
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    // 1) Foto anterior: se borra si la story se reemplazó o se eliminó.
    if (before?.imagePath && before.imagePath !== after?.imagePath) {
      await deleteFile(before.imagePath);
    }
    if (!after) return;

    // 2) Story nueva → avisar a la pareja.
    if (before?.storyId !== after.storyId) {
      const partner = await partnerOf(coupleId, ownerUid);
      if (!partner) return;
      const name = await nameOf(ownerUid);
      const message = (after.message as string | undefined)?.trim();
      await notify(
        partner,
        `${name} subió una story nueva 📸`,
        message || "Toca para verla",
        { type: "story", coupleId },
      );
      return;
    }

    // 3) Like nuevo → avisar a quien subió la story.
    if (!before?.likedAt && after.likedAt && after.likedBy) {
      const liker = await nameOf(after.likedBy as string);
      await notify(ownerUid, `A ${liker} le gustó tu story ❤️`, after.message || "", {
        type: "like",
        coupleId,
      });
    }
  },
);

export const cleanupExpiredStories = onSchedule("every 10 minutes", async () => {
  const expired = await db
    .collectionGroup("stories")
    .where("expiresAt", "<=", Timestamp.now())
    .limit(200)
    .get();
  // Al borrar el documento, onStoryWritten borra también la foto.
  await Promise.all(expired.docs.map((d) => d.ref.delete()));
  if (!expired.empty) logger.info(`Borradas ${expired.size} stories expiradas`);
});
