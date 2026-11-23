# Nosotros 💗

App privada para dos personas: cada quien manda **una foto tipo story con un
mensaje corto**, y la pantalla se divide en dos, tu story a la izquierda y la
de tu pareja a la derecha, cada una con la foto de perfil y el nombre de quien
la mandó.

## Cómo funciona

| Regla | Cómo se cumple |
|---|---|
| Solo dos personas | Se vinculan con un código de 6 dígitos. Cuando entra la segunda persona, el código se borra y nadie más puede unirse (lo controla el servidor y las reglas de seguridad). |
| Una story por persona | Cada persona tiene un solo "espacio" de story. Subir una nueva **sobrescribe** la anterior: la foto vieja deja de existir. |
| Duran 24 horas | Al cumplir 24 h la app la oculta (aunque no haya internet) y la borra de internet. |
| No se guardan | No hay historial ni galería. Solo puedes **descargarla** a tu teléfono o darle **like** ❤️. |
| Subir con internet, ver sin internet | La foto se guarda en el teléfono al llegar; se ve offline hasta que expira. |
| Avisos | En Android, la app revisa sola cada ~15 min y avisa: "Pepeta subió una story nueva 📸" o "A Momido le gustó tu story ❤️". |
| Gratis | Usa el plan gratis de Firebase (Spark), **sin tarjeta**. |
| Widget | Widget en la pantalla de inicio con la vista dividida (funciona sin internet). |

## Partes

- `lib/`: la app (Flutter: un solo código para Android y iPhone).
- `android/.../StoryWidgetProvider.kt`: widget de Android.
- `ios/StoryWidget/`: widget de iPhone.
- `firestore.rules`: seguridad (solo la pareja ve sus stories; máximo dos personas).

**Para instalarla, sigue [SETUP.md](SETUP.md).**
