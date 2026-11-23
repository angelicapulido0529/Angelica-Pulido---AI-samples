# Cómo poner a funcionar "Nosotros" (gratis)

Todo esto se hace **una sola vez** y **no pide tarjeta**. Se puede hacer desde el
navegador del celular (en Firebase conviene activar "Ver versión de escritorio").

**¿Qué es Firebase?** Un servicio gratuito de Google que hace de "puente"
entre los dos celulares: guarda sus cuentas y mantiene la story viva hasta que
la otra persona la recoge. La foto **no se guarda para siempre**: se borra al
subir otra o al cumplir 24 horas.

---

## 1. Crear el proyecto (plan gratis Spark)

1. Entra a <https://console.firebase.google.com> con tu cuenta de Google.
2. **Crear proyecto** → nombre `nosotros` → puedes desactivar Google Analytics.
   Queda en el plan **Spark (gratis)**. No cambies a Blaze.
3. Menú → **Authentication** → *Comenzar* → activa **Correo electrónico/contraseña**.
4. Menú → **Firestore Database** → *Crear base de datos* → ubicación cercana
   (por ejemplo `nam5` o `southamerica-east1`) → modo **producción**.

## 2. Pegar las reglas de seguridad

1. En **Firestore Database** → pestaña **Reglas**.
2. Borra lo que hay y pega todo el contenido del archivo
   [`firestore.rules`](firestore.rules) de este repositorio.
3. Toca **Publicar**.

Esto es lo que garantiza que solo ustedes dos vean sus stories.

## 3. Conectar la app con tu proyecto

1. En la página principal del proyecto toca el ícono de **Android**.
   - Nombre del paquete: `com.nosotrosapp.nosotros`
   - Toca *Registrar app* y descarga **`google-services.json`**.
   - Los demás pasos que muestra Firebase sáltalos (ya están hechos).
2. **Mándale ese archivo a Claude** (no es secreto). Claude llena
   `lib/firebase_options.dart` y vuelve a generar el APK.

## 4. Instalar en Android 📱

1. En GitHub → *Actions* → **Nosotros · APK Android** → *Run workflow*
   (también corre solo cada vez que cambia el código). Tarda unos 10 minutos.
2. Abre desde tu celular **Releases → "Nosotros (última versión)"** y descarga
   `Nosotros.apk`.
3. Ábrelo. Android pedirá permitir "instalar apps de fuentes desconocidas"
   para tu navegador: acéptalo.
4. Tu pareja hace lo mismo en su celular.

**Widget:** mantén presionada la pantalla de inicio → *Widgets* → **Nosotros**.

**Avisos:** acepta el permiso de notificaciones. Si tu celular es Xiaomi,
Huawei, Samsung, etc. y no llegan los avisos, en *Ajustes → Apps → Nosotros →
Batería* elige **Sin restricciones**.

> Si al actualizar Android dice "la app no es compatible", desinstala la
> anterior e instala la nueva (las stories no se pierden, están en Firebase).

## 5. iPhone 🍎

Apple solo permite instalar apps en un iPhone si se compilan en una Mac
(propia, prestada o rentada en la nube, por ejemplo con **Codemagic**) y con
una cuenta de **Apple Developer** ($99 USD al año). La app no corre en la Mac:
la Mac solo la "fabrica". Cuando quieras hacerlo, pídele a Claude los pasos.

En iPhone las stories, likes y el widget funcionan igual; los avisos llegan al
abrir la app (iOS no deja que una app gratuita revise en segundo plano de
forma confiable).

---

## Primer uso

1. Cada quien crea su cuenta (correo + contraseña), su nombre y su foto de perfil.
2. Uno toca **Crear código** y se lo pasa al otro.
3. El otro lo escribe en **Código de tu pareja** → **Unirme**. ¡Listo! 💗

## Límites del plan gratis

Sobradísimos para dos personas: 1 GB guardado, 50 000 lecturas y 20 000
escrituras al día. Una story pesa unos 200–400 KB y solo existe una por persona.
