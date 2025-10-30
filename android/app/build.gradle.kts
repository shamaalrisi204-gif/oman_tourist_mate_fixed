plugins {
   id("com.android.application")
   id("kotlin-android")
   id("com.google.gms.google-services")
   id("dev.flutter.flutter-gradle-plugin")
}
android {
   namespace = "com.oman.oman_tourist_mate_fixed"
   compileSdk = flutter.compileSdkVersion
   ndkVersion = flutter.ndkVersion
   defaultConfig {
       applicationId = "com.oman.oman_tourist_mate_fixed"
       minSdk = flutter.minSdkVersion
       targetSdk = flutter.targetSdkVersion
       versionCode = flutter.versionCode
       versionName = flutter.versionName
       multiDexEnabled = true
   }
   compileOptions {
       sourceCompatibility = JavaVersion.VERSION_11
       targetCompatibility = JavaVersion.VERSION_11
   }
   kotlinOptions {
       jvmTarget = JavaVersion.VERSION_11.toString()
   }
   buildTypes {
       // Debug: لا تصغير ولا حذف موارد
       getByName("debug") {
           isMinifyEnabled = false
           isShrinkResources = false
       }
       // Release: فعّل الاثنين
       getByName("release") {
           isMinifyEnabled = true
           isShrinkResources = true
           proguardFiles(
               getDefaultProguardFile("proguard-android.txt"),
               "proguard-rules.pro"
           )
       }
   }
   // لو كنتِ تستعملين ملفات res بالاتجاهين RTL
   buildFeatures {
       // اتركيها افتراضيًا، لا داعي لتفعيل شيء هنا لهذا الخطأ
   }
}
dependencies {
   // يضاف تلقائيًا عبر Flutter، لا حاجة لتعديل هنا
}