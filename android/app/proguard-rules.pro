# Jackson için eksik sınıflar
-dontwarn java.beans.**
-keep class java.beans.** { *; }

-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
-keep class org.w3c.dom.bootstrap.DOMImplementationRegistry { *; }
-dontwarn java.beans.ConstructorProperties
-keep class java.beans.ConstructorProperties { *; }
-dontwarn java.beans.Transient
-keep class java.beans.Transient { *; }


# Genel keep rules
-keep class com.fasterxml.** { *; }
