# Guia de publicação na App Store (iOS)

Este documento reúne o passo a passo para publicar o app `Cartela Mega Sena` na App Store.

## 1. Preparação do app

Antes de publicar, confirme que o app está funcionando em release:

```bash
cd /home/s630589102/wrk-kiro/wrk-antigravity/mega-sena
flutter clean
flutter pub get
flutter test
flutter build ios --release
```

Se o app não compilar, corrija os erros antes de continuar.

## 2. Configurar nome do app

No arquivo `ios/Runner/Info.plist`, confirme o nome exibido:

```xml
<key>CFBundleDisplayName</key>
<string>Cartela Mega Sena</string>
```

## 3. Definir o Bundle ID

O identificador único do app deve ser:

```text
com.cartela_loteria.megasena
```

No Xcode, em `Runner > General > Bundle Identifier`, configure:

```text
com.cartela_loteria.megasena
```

## 4. Definir versão

No arquivo `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Para lançar uma nova versão, incremente:

```yaml
version: 1.0.1+1
```

## 5. Configurar assinatura Apple

Você precisará de:

- conta Apple Developer Program ativa
- certificado de distribuição
- provisioning profile
- chave de assinatura para upload

No Xcode:

1. Abra o projeto em Xcode
2. Selecione `Runner`
3. Em `Signing & Capabilities`
4. Marque `Automatically manage signing`
5. Escolha a conta Apple correta
6. Verifique se o bundle ID bate com o registrado

## 6. Gerar o build para release

Abra o Xcode e faça:

- `Product > Scheme > Runner`
- selecionar `Any iOS Device (arm64)`
- `Product > Archive`

Ou via terminal:

```bash
flutter build ios --release
```

## 7. Enviar para a App Store

Após o Archive:

1. O Xcode abre a janela de Archive
2. Clique em `Distribute App`
3. Escolha `App Store Connect`
4. Continue com as etapas
5. Faça upload do build
6. Faça login na conta Apple

## 8. Criar o app no App Store Connect

Acesse: https://appstoreconnect.apple.com/

1. Clique em `My Apps`
2. `+` > `New App`
3. Preencha:
   - Platforms: iOS
   - Name: `Cartela Mega Sena`
   - Primary Language: Português (Brasil) ou Inglês
   - Bundle ID: `com.cartela_loteria.megasena`
   - SKU: `cartela-mega-sena`
4. Salve o app

## 9. Preencher dados da loja

No App Store Connect, configure:

- Nome do app
- Subtítulo
- Descrição
- Categoria principal
- Conteúdo de privacidade
- Política de privacidade
- Capturas de tela
- Ícone
- Link para privacidade

## 10. Preparar screenshots

Você precisará de imagens para:

- iPhone 6.5"
- iPhone 5.5"
- e outras variações conforme a Apple

## 11. Enviar para revisão

No App Store Connect:

1. Selecione o app
2. Vá em `App Store > Prepare for Submission`
3. Preencha todos os campos obrigatórios
4. Clique em `Submit for Review`

A revisão da Apple geralmente leva alguns dias.

## 12. Publicar

Quando a aprovação for concluída:

- o app pode ficar disponível na App Store
- ou pode ser liberado em `Manual Release` ou `Automatic Release`

## Dicas importantes

- Use nome e bundle ID consistentes
- Teste em dispositivos reais antes da publicação
- Revise políticas de privacidade e termos de uso
- Tenha o ícone e splash prontos no app
- Evite versões com build quebrado ou sem certificados válidos

## Comandos úteis

```bash
flutter clean
flutter pub get
flutter build ios --release
```

## Checklist final

- [ ] App compilando
- [ ] Nome definido
- [ ] Bundle ID correto
- [ ] Versão configurada
- [ ] Certificado de distribuição ativo
- [ ] App no App Store Connect criado
- [ ] Screenshots e descrição preenchidas
- [ ] Build enviado
- [ ] Requisição de revisão enviada
