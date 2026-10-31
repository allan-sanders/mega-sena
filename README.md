# Mega-Sena Smart (Flutter - iOS & Android)

Aplicativo móvel multiplataforma (**iPhone e Android**) desenvolvido em **Flutter** para geração estatística de jogos da Mega-Sena com controle de apostas realizadas.

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
5. **Gerador em Lote (Até 999 Jogos), Adição Sem Repetição e Controle de Jogos Realizados**:
   - Permite combinar múltiplos tamanhos de jogos em um único pedido (respeitando o teto global de **999 jogos** na base).
   - **Adicionar Jogos (`ADICIONAR JOGOS`)**: Preserva todos os jogos atuais (inclusive os que já foram marcados como realizados), calcula a cota restante até 999, continua a numeração sequencial e garante **zero repetição** tanto entre os novos jogos quanto em relação aos jogos já existentes na base.
   - **Novo Lote (`NOVO LOTE`)**: Exibe um alerta de confirmação informando quantos jogos realizados/pendentes existem na base e, ao confirmar, exclui os jogos atuais para gerar um novo combinado do zero.
   - Permite marcar quais jogos já foram realizados (`REALIZADO`) com barra de progresso animada e filtros (`Todos`, `Pendentes`, `Realizados`).

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

# 4. Rode no iPhone (Simulator/Dispositivo) ou Android (Emulador/Dispositivo):
flutter run
```
