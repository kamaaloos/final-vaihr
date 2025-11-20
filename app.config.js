import 'dotenv/config';
import appJson from './app.json';

export default {
  expo: {
    ...appJson.expo,
    owner: "mayloos",
    assetBundlePatterns: [
      "assets/**/*",
      "src/**/*"
    ],
    plugins: [
      "expo-asset",
      "expo-video"
    ],
    extra: {
      supabaseUrl: process.env.EXPO_PUBLIC_SUPABASE_URL,
      supabaseAnonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
      supabaseServiceKey: process.env.EXPO_PUBLIC_SUPABASE_SERVICE_ROLE_KEY,
      projectId: process.env.EXPO_PUBLIC_PROJECT_ID,
      "eas": {
        "projectId": "1d6eff74-12ce-45fd-8491-c0e1e3fb6ed4"
      }
    }
  }
}; 