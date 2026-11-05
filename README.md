# Dezena Certa MS (Flutter - Android)

Aplicativo móvel desenvolvido em Flutter para geração estatística de jogos da Mega-Sena com sincronização dos últimos 100 concursos e controle de combinações geradas.

---

## Nome e marca

- Nome de publicação sugerido: `Dezena Certa MS`
- Nome de exibição no app: `Dezena Certa MS`
- E-mail de contato do responsável: `pattymagno14@gmail.com`

Antes da publicação, confirme disponibilidade do nome e uso de marca na Google Play.

---

## Funcionalidades Implementadas

1. **Login Exclusivo Google (`google_sign_in`)**:
   - Autenticação rápida com conta Google e persistência local no dispositivo.
2. **Sincronização Semanal Inteligente (Base: Domingo)**:
   - Sincroniza os **últimos 100 concursos** da Mega-Sena na API Oficial da Caixa (`servicebus2.caixa.gov.br/portaldeloterias/api/megasena`) com fallback automático para espelho e semente offline.
   - **Regra do Domingo**: Se o app já atualizou a base no domingo (ou durante a semana corrente), novos acessos na segunda, terça, etc. reutilizam a base consolidada da semana e só realizam nova sincronização a partir do próximo domingo.
3. **Classificação 30% / 40% / 30%**:
   - Ordena as 60 dezenas pela frequência nos últimos 100 sorteios (com desempate determinístico por concurso mais recente):
     - **Mais Sorteados (`q` - 30%)**: 18 dezenas
     - **Moderados (`m` - 40%)**: 24 dezenas
     - **Menos Sorteados (`b` - 30%)**: 18 dezenas
4. **Matriz Oficial de Distribuição (6 a 20 Dezenas)**:
   - `6 dez`: 3q, 2m, 1b
   - `7 dez`: 4q, 2m, 1b
   - `8 dez`: 4q, 3m, 1b
   - `9 dez`: 4q, 4m, 1b
   - `10 dez`: 4q, 4m, 2b
   - `11 dez`: 5q, 4m, 2b
   - `12 dez`: 6q, 4m, 2b
   - `13 dez`: 6q, 5m, 2b
   - `14 dez`: 6q, 5m, 3b
   - `15 dez`: 7q, 5m, 3b
   - `16 dez`: 7q, 6m, 3b
   - `17 dez`: 8q, 6m, 3b
   - `18 dez`: 8q, 7m, 3b
   - `19 dez`: 8q, 7m, 4b
   - `20 dez`: 9q, 7m, 4b
5. **Gerador em Lote e Gestão Avançada (Até 999 Jogos)**:
   - **Adicionar Jogos**: Adiciona novas combinações mantendo as atuais e impedindo repetições.
   - **Novo Lote**: Apaga base atual para criar um conjunto do zero.
   - **Inserção Manual (`MANUAL`)**: Modal de escolha manual (6 a 20 dezenas). Jogos inseridos manualmente integram a base e respeitam o limite de 999.
   - **Exportar Jogos (`Compartilhar`)**: Formata a lista completa com marcações de PENDENTE/REALIZADO em texto, permitindo rápido envio no WhatsApp ou impressão.
   - **Excluir Jogo**: Cada cartela gerada pode ser excluída individualmente (ícone Lixeira).

---

## Importante sobre persistência e combinações geradas

A funcionalidade de evitar repetição de combinações geradas funciona com base local no dispositivo. O histórico fica salvo em `SharedPreferences` e não é sincronizado entre aparelhos ou re-instalações por padrão (entretanto as atualizações de APK por cima mantêm a base intacta).

Se a intenção for persistência cross-device, será necessário implementar backup em nuvem. Até lá, a interface e a descrição devem informar claramente essa limitação.

---

## Como Executar o Projeto

Certifique-se de ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado em sua máquina:

```bash
# 1. Caso as pastas nativas android/ e ios/ ainda não existam no clone, gere-as com:
flutter create . --platforms=android,ios

# 2. Instale os pacotes:
flutter pub get

# 3. Execute os testes automatizados das regras de negócio:
flutter test

# 4. Rode no Android (Emulador/Dispositivo):
flutter run
```

---

## Gerar o arquivo para publicação

Para gerar o bundle Android de release para Google Play:

```bash
cd /home/s630589102/wrk-kiro/wrk-antigravity/mega-sena
flutter clean
flutter pub get
flutter build appbundle
```
