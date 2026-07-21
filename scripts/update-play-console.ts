import { google } from 'googleapis';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Service Account JSON key path
const KEY_PATH = process.env.PLAY_STORE_CREDENTIALS_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS || 'C:\\Users\\DeLL\\.config\\play-service-account.json';
const CREDENTIALS_JSON = process.env.PLAY_STORE_CREDENTIALS_JSON;
const PACKAGE_NAME = process.env.PACKAGE_NAME || 'com.heicflow.heicflow'; 

// 🚀 HEICFlow 10/10 Masterclass Localizations
const localizations = [
  {
    language: 'en-US',
    title: 'HEIC to JPG Converter HEICFlow',
    shortDesc: 'Convert HEIC photos to JPG, PNG & PDF offline. Fast batch photo converter!',
    fullDesc: `Convert iPhone HEIC and HEIF photos to JPG, PNG, or PDF formats in seconds—100% on-device, fast, and completely private!\n\nHEICFlow is the ultimate batch photo converter designed to process your high-efficiency photos locally on your phone without uploading your private images to external servers.\n\n🌟 KEY FEATURES:\n• BATCH CONVERT: Select and convert dozens of HEIC/HEIF files simultaneously to JPG or PNG.\n• PDF MERGER: Combine multiple HEIC photos into a clean, single PDF document for easy sharing.\n• 100% PRIVATE & OFFLINE: Your photos never leave your device. Conversion is performed on-device using local decoders.\n• QUALITY CONTROL: Adjust JPEG compression quality (60% to 100%) to balance file size and clarity.\n• EXIF PRESERVATION: Retain original photo dates, resolution, and metadata.\n• RECENT HISTORY: Keep track of your last 20 export sessions to re-share or open converted files instantly.\n\nWHY CHOOSE HEICFLOW?\nStandard online HEIC converters require uploading your personal photos to third-party servers. HEICFlow provides 100% local processing with zero data tracking, making it the fastest and safest converter for iOS and Android.\n\nDownload HEICFlow today and simplify your photo sharing across all devices!`
  },
  {
    language: 'ja-JP',
    title: 'HEIC JPG 変換 HEICFlow',
    shortDesc: 'iPhoneのHEIC写真をJPG、PNG、PDFに一括変換。オフラインで安全！',
    fullDesc: `iPhoneのHEICおよびHEIF写真を数秒でJPG、PNG、またはPDF形式に変換。100%デバイス上で高速かつ完全プライベートに処理！\n\nHEICFlowは、写真を外部サーバーにアップロードすることなくローカルで処理する一括写真変換アプリです。\n\n🌟 主な機能：\n• 一括変換：複数のHEIC/HEIFファイルを指定して、JPGまたはPNGに同時変換。\n• PDF統合：複数のHEIC写真を1つの綺麗なPDFドキュメントに結合。\n• 100%プライベート＆オフライン：写真がデバイス外に送信されることはありません。\n• 画質コントロール：JPEG圧縮品質（60%〜100%）を調整可能。\n• EXIF情報保持：撮影日時、解像度、メタデータを維持。\n\n今すぐHEICFlowをダウンロードして、すべてのデバイスで写真共有を快適に！`
  },
  {
    language: 'de-DE',
    title: 'HEIC in JPG Umwandeln HEICFlow',
    shortDesc: 'HEIC Fotos in JPG, PNG & PDF umwandeln. Schneller Batch Konverter offline!',
    fullDesc: `Konvertieren Sie iPhone HEIC & HEIF Fotos in Sekunden in JPG, PNG oder PDF – 100% lokal auf Ihrem Gerät und absolut privat!\n\nHEICFlow ist der ultimative Batch-Fotokonverter zum lokalen Verarbeiten Ihrer Bilder ohne Cloud-Upload.\n\n🌟 HAUPTMERKMALE:\n• BATCH-UMWANDLUNG: Mehrere HEIC/HEIF-Dateien gleichzeitig in JPG oder PNG umwandeln.\n• PDF-ZUSAMMENFÜHRUNG: Mehrere Fotos in einem einzigen PDF-Dokument zusammenfassen.\n• 100% PRIVAT & OFFLINE: Ihre Fotos verlassen nie Ihr Smartphone.\n• QUALITÄTSKONTROLLE: JPEG-Komprimierung (60% bis 100%) individuell anpassen.\n• EXIF-METADATEN ERHALTEN: Aufnahmedatum, Auflösung und Metadaten bleiben erhalten.\n\nLaden Sie HEICFlow noch heute herunter!`
  },
  {
    language: 'fr-FR',
    title: 'Convertisseur HEIC en JPG',
    shortDesc: 'Convertissez photos HEIC en JPG, PNG et PDF hors-ligne. Rapide et privé !',
    fullDesc: `Convertissez vos photos HEIC et HEIF iPhone en JPG, PNG ou PDF en quelques secondes — 100% hors-ligne, rapide et totalement privé !\n\nHEICFlow est le convertisseur photo par lot ultime conçu pour traiter vos images localement sans les envoyer vers des serveurs tiers.\n\n🌟 FONCTIONNALITÉS EN VEDETTE:\n• CONVERSION PAR LOT: Choisissez et convertissez des dizaines de fichiers HEIC en JPG ou PNG.\n• FUSION PDF: Combinez plusieurs photos HEIC dans un document PDF unique.\n• 100% PRIVÉ & HORS-LIGNE: Vos photos ne quittent jamais votre appareil.\n• CONTRÔLE QUALITÉ: Ajustez la compression JPEG de 60% à 100%.\n• CONSERVATION EXIF: Conservez la date, la résolution et les métadonnées d'origine.\n\nTéléchargez HEICFlow dès aujourd'hui !`
  },
  {
    language: 'es-ES',
    title: 'Convertidor HEIC a JPG',
    shortDesc: 'Convierte fotos HEIC a JPG, PNG y PDF sin internet. ¡Rápido y privado!',
    fullDesc: `Convierte tus fotos HEIC y HEIF de iPhone a JPG, PNG o PDF en segundos: 100% local en tu dispositivo, rápido y completamente privado.\n\nHEICFlow es el convertidor por lotes definitivo diseñado para procesar tus imágenes sin subir fotos a servidores externos.\n\n🌟 CARACTERÍSTICAS PRINCIPALES:\n• CONVERSIÓN EN LOTE: Selecciona y convierte docenas de archivos HEIC a JPG o PNG.\n• UNIR EN PDF: Combina múltiples fotos HEIC en un archivo PDF ordenado.\n• 100% PRIVADO Y SIN INTERNET: Tus fotos nunca salen de tu dispositivo.\n• CONTROL DE CALIDAD: Ajusta la compresión JPEG del 60% al 100%.\n• CONSERVA METADATOS EXIF: Mantiene la fecha original y la resolución de la foto.\n\n¡Descarga HEICFlow hoy mismo!`
  }
];

async function updateMetadata() {
  if (!CREDENTIALS_JSON && !fs.existsSync(KEY_PATH)) {
    console.error(`🚨 ERROR: Service account key not found at ${KEY_PATH} and PLAY_STORE_CREDENTIALS_JSON is not set`);
    process.exit(1);
  }

  console.log('Authenticating with Google Play Developer API...');
  const authOptions: any = {
    scopes: ['https://www.googleapis.com/auth/androidpublisher']
  };

  if (CREDENTIALS_JSON) {
    authOptions.credentials = JSON.parse(CREDENTIALS_JSON);
  } else {
    authOptions.keyFile = KEY_PATH;
  }

  const auth = new google.auth.GoogleAuth(authOptions);

  const authClient = await auth.getClient();
  const androidPublisher = google.androidpublisher({
    version: 'v3',
    auth: authClient as any
  });

  try {
    console.log(`Starting edit for package: ${PACKAGE_NAME}`);
    const edit = await androidPublisher.edits.insert({
      packageName: PACKAGE_NAME,
      requestBody: {}
    });

    const editId = edit.data.id;
    if (!editId) throw new Error("Failed to create edit ID");

    for (const loc of localizations) {
      console.log(`🌍 Updating ${loc.language} metadata listing...`);
      await androidPublisher.edits.listings.update({
        packageName: PACKAGE_NAME,
        editId: editId,
        language: loc.language,
        requestBody: {
          title: loc.title,
          shortDescription: loc.shortDesc,
          fullDescription: loc.fullDesc
        }
      });
      console.log(`✅ ${loc.language} updated.`);
    }

    console.log('Validating edit...');
    await androidPublisher.edits.validate({
      packageName: PACKAGE_NAME,
      editId: editId
    });

    console.log('Committing changes to Google Play Console...');
    await androidPublisher.edits.commit({
      packageName: PACKAGE_NAME,
      editId: editId
    });

    console.log('🎉 SUCCESS! All ASO metadata published to Google Play Console!');

  } catch (error: any) {
    console.error('❌ Failed to update Google Play Console metadata:');
    if (error.response && error.response.data) {
      console.error(error.response.data.error.message);
    } else {
      console.error(error);
    }
    process.exit(1);
  }
}

updateMetadata().catch(console.error);
