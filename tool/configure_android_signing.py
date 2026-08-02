from pathlib import Path

app_dir = Path('android/app')
kts = app_dir / 'build.gradle.kts'
groovy = app_dir / 'build.gradle'
package_id = 'com.primeinnovationthinking.oraculodiosafortuna'

if kts.exists():
    text = kts.read_text(encoding='utf-8')
    if 'import java.util.Properties' not in text:
        text = 'import java.util.Properties\nimport java.io.FileInputStream\n\n' + text
    text = text.replace('namespace = "com.primeinnovationthinking.oraculo_diosa_fortuna"', f'namespace = "{package_id}"')
    text = text.replace('applicationId = "com.primeinnovationthinking.oraculo_diosa_fortuna"', f'applicationId = "{package_id}"')
    marker = 'android {\n'
    signing_setup = '''android {\n    val keystoreProperties = Properties()\n    val keystorePropertiesFile = rootProject.file("key.properties")\n    if (keystorePropertiesFile.exists()) {\n        keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n    }\n'''
    if 'val keystoreProperties = Properties()' not in text:
        text = text.replace(marker, signing_setup, 1)
    build_marker = '    buildTypes {\n'
    signing_block = '''    signingConfigs {\n        create("release") {\n            keyAlias = keystoreProperties["keyAlias"] as String?\n            keyPassword = keystoreProperties["keyPassword"] as String?\n            storeFile = keystoreProperties["storeFile"]?.let { file(it) }\n            storePassword = keystoreProperties["storePassword"] as String?\n        }\n    }\n\n    buildTypes {\n'''
    if 'create("release")' not in text:
        text = text.replace(build_marker, signing_block, 1)
    text = text.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
    kts.write_text(text, encoding='utf-8')
elif groovy.exists():
    text = groovy.read_text(encoding='utf-8')
    text = text.replace('namespace "com.primeinnovationthinking.oraculo_diosa_fortuna"', f'namespace "{package_id}"')
    text = text.replace('applicationId "com.primeinnovationthinking.oraculo_diosa_fortuna"', f'applicationId "{package_id}"')
    header = '''def keystoreProperties = new Properties()\ndef keystorePropertiesFile = rootProject.file('key.properties')\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n}\n\n'''
    if 'def keystoreProperties = new Properties()' not in text:
        text = header + text
    marker = '    buildTypes {\n'
    block = '''    signingConfigs {\n        release {\n            keyAlias keystoreProperties['keyAlias']\n            keyPassword keystoreProperties['keyPassword']\n            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null\n            storePassword keystoreProperties['storePassword']\n        }\n    }\n\n    buildTypes {\n'''
    if 'signingConfigs {' not in text:
        text = text.replace(marker, block, 1)
    text = text.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
    groovy.write_text(text, encoding='utf-8')
else:
    raise SystemExit('No Android Gradle app file found. Run flutter create first.')
