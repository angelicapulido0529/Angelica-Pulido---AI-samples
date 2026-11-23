# Cómo poner a funcionar "Nosotros"

Todo esto se hace **una sola vez**. Se puede hacer desde el navegador del celular
(en Firebase conviene activar "Ver versión de escritorio").

---

## 1. Crear el proyecto en Firebase (el servidor)

1. Entra a <https://console.firebase.google.com> → **Crear proyecto** → ponle `nosotros`.
2. **Plan Blaze**: en el menú, ⚙️ → *Uso y facturación* → cambia a **Blaze**.
   Pide una tarjeta, pero para dos personas el uso queda dentro de lo gratuito
   ($0). Recomendado: crea una alerta de presupuesto de $1 para estar tranquila.
   (Sin Blaze no funcionan las notificaciones ni el borrado automático.)
3. **Authentication** → *Comenzar* → activa **Correo electrónico/contraseña**.
4. **Firestore Database** → *Crear base de datos* → modo **producción** → región
   `us-central1` (o la más cercana).
5. **Storage** → *Comenzar* → modo **producción** → misma región.

## 2. Conectar la app con tu proyecto

1. En la página principal del proyecto, toca el ícono de **Android** para
   agregar una app.
   - Nombre del paquete: `com.nosotrosapp.nosotros`
   - Descarga el archivo `google-services.json`.
2. (Para iPhone) agrega también una app **iOS** con el ID
   `com.nosotrosapp.nosotros` y descarga `GoogleService-Info.plist`.
3. **Pásale esos archivos a Claude** (no son secretos) y él llena
   `lib/firebase_options.dart`. O hazlo tú: reemplaza cada `PENDIENTE` así:

   | En `firebase_options.dart` | En `google-services.json` |
   |---|---|
   | `_projectId` | `project_info.project_id` |
   | `_messagingSenderId` | `project_info.project_number` |
   | `_storageBucket` | `project_info.storage_bucket` |
   | `android.apiKey` | `client[0].api_key[0].current_key` |
   | `android.appId` | `client[0].client_info.mobilesdk_app_id` |

   Para iOS: `API_KEY` y `GOOGLE_APP_ID` de `GoogleService-Info.plist`.

## 3. Subir el servidor y las reglas de seguridad

**Opción A — sin computadora (con GitHub):**

1. Firebase → ⚙️ *Configuración del proyecto* → **Cuentas de servicio** →
   *Generar nueva clave privada*. Se descarga un `.json`.
2. En <https://console.cloud.google.com/iam-admin/iam> (mismo proyecto),
   edita la cuenta `firebase-adminsdk-…` y agrégale el rol **Propietario**
   (Owner). Esta clave es como una llave maestra: guárdala solo en GitHub.
3. En GitHub, en este repositorio: *Settings* → *Secrets and variables* →
   *Actions* → **New repository secret**
   - Nombre: `FIREBASE_SERVICE_ACCOUNT`
   - Valor: pega todo el contenido del `.json`.
4. *Actions* → **Nosotros · Firebase** → *Run workflow* → escribe el ID del
   proyecto (ej. `nosotros-1a2b3`) → *Run*.

**Opción B — con una computadora (Windows/Linux/Mac):**

```bash
npm install -g firebase-tools
firebase login
cd nosotros
firebase deploy --project TU_ID_DE_PROYECTO --only firestore,storage,functions
```

## 4. Instalar en Android 📱

1. En GitHub → *Actions* → **Nosotros · APK Android** → *Run workflow*
   (también corre solo cada vez que cambia el código).
2. Cuando termine (unos 10 min), abre **Releases → "Nosotros (última versión)"**
   desde tu celular y descarga `Nosotros.apk`.
3. Ábrelo. Android te pedirá permitir "instalar apps de fuentes desconocidas"
   para tu navegador: acéptalo.
4. Tu pareja hace lo mismo en su celular.

**Widget:** mantén presionada la pantalla de inicio → *Widgets* → **Nosotros**.

> Si al actualizar Android dice "la app no es compatible", desinstala la
> anterior e instala la nueva (las stories no se pierden, están en el servidor).
> Para evitarlo, pide a Claude que genere una llave de firma
> (`ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD`).

## 5. Instalar en iPhone 🍎

Apple no permite instalar apps en un iPhone sin pasar por sus herramientas:

- Hace falta una **cuenta de Apple Developer** ($99 USD al año). También la
  piden las notificaciones push en iPhone.
- Hace falta **compilar en una Mac**, propia, prestada, o rentada en la nube
  con un servicio como **Codemagic** (tiene plan gratis y compila sin tener
  Mac). La app se instala después en el iPhone con **TestFlight**. La app no
  corre en la Mac: la Mac solo la "fabrica".

Pasos en la Mac (o en Codemagic), una sola vez:

1. `cd nosotros && flutter pub get && open ios/Runner.xcworkspace`
2. En Xcode, target **Runner** → *Signing & Capabilities*: elige tu equipo y
   agrega **Push Notifications**, **Background Modes** (*Remote notifications*)
   y **App Groups** → `group.com.nosotrosapp.nosotros`.
3. **Widget:** *File → New → Target → Widget Extension* → nombre `StoryWidget`
   (sin "Live Activity" ni "Configuration Intent"). Borra el archivo `.swift`
   que crea Xcode y agrega `ios/StoryWidget/StoryWidget.swift`. En
   *Signing & Capabilities* del widget agrega **App Groups** →
   `group.com.nosotrosapp.nosotros`. Versión mínima del widget: iOS 17.
4. En Firebase → ⚙️ → *Cloud Messaging* → sube tu **clave APNs** (se crea en
   developer.apple.com → *Keys*).
5. *Product → Archive* → *Distribute* → **TestFlight**. Instálala desde la
   app TestFlight en el iPhone.

**Widget en iPhone:** mantén presionada la pantalla de inicio → **+** → **Nosotros**.

---

## Primer uso

1. Cada quien crea su cuenta (correo + contraseña), su nombre y su foto de perfil.
2. Uno toca **Crear código** y se lo pasa al otro.
3. El otro lo escribe en **Código de tu pareja** → **Unirme**. ¡Listo! 💗
