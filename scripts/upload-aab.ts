import { google } from 'googleapis';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// The path to your Google Play Service Account JSON key
const KEY_PATH = process.env.PLAY_STORE_CREDENTIALS_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS || 'C:\\Users\\DeLL\\.config\\play-service-account.json';
const CREDENTIALS_JSON = process.env.PLAY_STORE_CREDENTIALS_JSON;
const PACKAGE_NAME = process.env.PACKAGE_NAME || 'com.heicflow.heicflow';
const TRACK = process.env.TRACK || 'alpha'; // default to 'alpha' for closed testing

async function uploadAab() {
  if (!CREDENTIALS_JSON && !fs.existsSync(KEY_PATH)) {
    console.error(`🚨 ERROR: Service account key not found at ${KEY_PATH} and PLAY_STORE_CREDENTIALS_JSON is not set`);
    process.exit(1);
  }

  const aabPath = path.join(__dirname, '../build/app/outputs/bundle/release/app-release.aab');
  if (!fs.existsSync(aabPath)) {
    console.error(`🚨 ERROR: AAB file not found at ${aabPath}`);
    console.error('Make sure you run "flutter build appbundle --release" first!');
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

    console.log('Uploading AAB file... This may take a minute.');
    const uploadRes = await androidPublisher.edits.bundles.upload({
      packageName: PACKAGE_NAME,
      editId: editId,
      media: {
        mimeType: 'application/octet-stream',
        body: fs.createReadStream(aabPath)
      }
    });

    const versionCode = uploadRes.data.versionCode;
    console.log(`✅ AAB uploaded successfully! Version Code: ${versionCode}`);

    console.log(`Assigning release to the '${TRACK}' track...`);
    await androidPublisher.edits.tracks.update({
      packageName: PACKAGE_NAME,
      editId: editId,
      track: TRACK,
      requestBody: {
        releases: [{
          name: `Release ${versionCode}`,
          versionCodes: [versionCode?.toString() || ""],
          status: 'completed'
        }]
      }
    });

    console.log('Committing changes to Google Play Console...');
    await androidPublisher.edits.commit({
      packageName: PACKAGE_NAME,
      editId: editId
    });

    console.log(`🎉 SUCCESS! The AAB is now assigned to '${TRACK}' closed testing track on Google Play Console.`);

  } catch (error: any) {
    console.error('❌ Failed to upload to Google Play Console:');
    if (error.response && error.response.data) {
      console.error(error.response.data.error.message);
    } else {
      console.error(error);
    }
    process.exit(1);
  }
}

uploadAab().catch(console.error);
