const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializar Firebase Admin SDK
admin.initializeApp();

// Función que se ejecuta cuando se crea un nuevo anuncio en Firestore
exports.notificarNuevoAnuncio = functions.firestore
  .document('anuncios/{anuncioId}')
  .onCreate(async (snap, context) => {
    const anuncio = snap.data();

    // Validar contenido mínimo
    const titulo = anuncio.titulo || "Nuevo anuncio";
    const descripcion = anuncio.descripcion || "Se ha añadido un nuevo anuncio";

    const payload = {
      notification: {
        title: titulo,
        body: descripcion,
      },
      topic: "todos", // Asegúrate que todos los dispositivos estén suscritos a este topic
    };

    try {
      await admin.messaging().send(payload);
      console.log("✅ Notificación enviada correctamente al topic 'todos'.");
    } catch (error) {
      console.error("❌ Error al enviar la notificación:", error);
    }
  });
