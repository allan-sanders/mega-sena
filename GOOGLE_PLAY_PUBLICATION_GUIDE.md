# Guia de publicação na Google Play

Este documento reúne o passo a passo para publicar o app `Dezena Certa MS` na Google Play.

## 1. Preparação do app

Antes de publicar, valide que o aplicativo está funcionando em release:

```bash
cd /home/s630589102/wrk-kiro/wrk-antigravity/mega-sena
flutter clean
flutter pub get
flutter test
flutter build appbundle
```

Se o app não compilar, corrija os erros antes de continuar.

## 2. Definir o nome do app

No Android, no arquivo `android/app/src/main/AndroidManifest.xml`, confirme o nome:

```xml
<application
    android:label="Dezena Certa MS"
    ... >
```

## 3. Definir o package ID

Use o identificador:

```text
com.dezenacerta.ms
```

No arquivo `android/app/build.gradle.kts`:

```gradle
defaultConfig {
    applicationId = "com.dezenacerta.ms"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

## 4. Definir a versão

No arquivo `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- `1.0.0` = versão pública
- `1` = build number

Para uma nova versão:

```yaml
version: 1.0.1+1
```

## 5. Criar conta de desenvolvedor Google Play

Acesse:

https://play.google.com/console/

Você precisará:

- conta Google
- pagar a taxa de cadastro da Google Play
- verificar identidade da conta

## 6. Criar o app na Google Play Console

1. Clique em `Create app`
2. Escolha `Android`
3. Preencha:
   - App name: `Dezena Certa MS`
   - Default language: Português (Brasil)
   - App or game: App
   - Free or paid: Free
4. Clique em `Create app`

## 7. Gerar o AAB

No terminal, gere o bundle de release:

```bash
cd /home/s630589102/wrk-kiro/wrk-antigravity/mega-sena
flutter build appbundle
```

O arquivo gerado fica em:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 8. Assinar o app

Para publicar na Play Store, o app precisa estar assinado com uma keystore de release.

Crie a keystore:

```bash
keytool -genkeypair -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Configure o `key.properties` em `android/key.properties` com:

```properties
storePassword=SuaSenha
keyPassword=SuaSenha
keyAlias=upload
storeFile=/home/seu-usuario/upload-keystore.jks
```

Ajuste o `android/app/build.gradle.kts` para usar a assinatura de release.

## 9. Fazer upload do AAB

No Google Play Console:

1. Selecione o app
2. Vá em `Release` > `Production`
3. Clique em `Create new release`
4. Faça upload do arquivo `.aab`
5. Complete o formulário da release

## 10. Preencher dados da loja

Configure:

- Nome do app: `Dezena Certa MS`
- Descrição curta
- Descrição completa
- Categoria
- Conteúdo da app
- Política de privacidade
- Capturas de tela
- Ícone do app
- Feature graphic
- E-mail de contato: `pattymagno14@gmail.com`

## 11. Screenshots e ícones

Você precisará de:

- ícone do app em vários tamanhos
- feature graphic
- screenshots para dispositivos Android

## 12. Política de privacidade

Você precisa de uma URL com a política de privacidade do app, especialmente se o app coleta dados. Exemplo:

```text
https://seusite.com/politica-privacidade
```

## 13. Enviar para revisão

No Google Play Console:

1. Complete todos os campos obrigatórios
2. Clique em `Review and publish`
3. Confirme
4. Envie para revisão

A revisão pode levar de algumas horas a alguns dias.

## 14. Publicar

Quando aprovado:

- o app pode entrar em produção
- ou ficar em rollout controlado

## Dicas importantes

- Sempre use o mesmo package ID do app
- Revise nome, ícone, screenshots e descrição antes de publicar
- Teste a release em dispositivo real antes do upload
- Mantenha a versão incremental e consistente
- Tenha política de privacidade e termos de uso listados
- Use o e-mail de suporte `pattymagno14@gmail.com` como contato do app

## Comandos úteis

```bash
flutter clean
flutter pub get
flutter build appbundle
```

## Checklist final

- [ ] App compilando
- [ ] Nome do app definido
- [ ] Package ID correto
- [ ] Versão configurada
- [ ] Keystore de release criada
- [ ] AAB gerado
- [ ] App criado no Google Play Console
- [ ] Política de privacidade adicionada
- [ ] Screenshots e ícone enviados
- [ ] E-mail de suporte informado
- [ ] Release enviada para revisão
