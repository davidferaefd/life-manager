# Life Manager

Aplicativo Flutter para organizar rotinas domésticas, estudos, trabalho e evolução pessoal.

## Funcionalidades

- **Casa:** cadastro, edição e exclusão de rotinas recorrentes, seleção de
  horário e dias, filtros por estado e marcação diária.
- **Estudos & Inglês:** plano de estudos, Pomodoro de foco/pausa e lista local
  de vocabulário com controle de revisões.
- **Trabalho:** quadro Kanban com arrastar e soltar entre A Fazer, Fazendo e
  Concluído.
- **Resumo:** nível, XP, ofensiva atual, progresso diário e gráfico de tarefas
  concluídas nos últimos 30 dias.
- **Dados locais:** tarefas, conclusões, histórico de XP, perfil e vocabulário
  são salvos no dispositivo com SharedPreferences.
- **Interface:** Material 3, tema escuro e navegação inferior entre as quatro
  áreas.

O horário é armazenado como minutos desde meia-noite e convertido para/de
`TimeOfDay`. Os dias da semana usam os valores `1` (segunda-feira) a `7`
(domingo), conforme `DateTime.weekday`.

## Estrutura do código

- `lib/models/`: modelos e serialização dos dados.
- `lib/screens/`: telas principais.
- `lib/services/`: estado compartilhado e persistência local.
- `lib/widgets/`: componentes reutilizáveis e formulários.

## Executar

```bash
flutter pub get
flutter run
```

## Testes e análise

```bash
flutter analyze
flutter test
```

## Preparar publicação Android

O identificador do aplicativo é `br.com.david.lifemanager`. Confirme que esse
identificador é seu e que ainda não está sendo usado no Google Play.

Para uma build assinada de release:

1. Confirme a disponibilidade e a titularidade do identificador do app no
   Google Play. Após a primeira publicação, não será possível trocá-lo.
2. Crie uma chave de upload Android e guarde com segurança o arquivo `.jks` e
   suas senhas. Nunca compartilhe ou versione esses segredos; faça backup
   seguro.
3. Crie `android/key.properties` localmente com os valores abaixo. O arquivo já
   está excluído do Git:

   ```properties
   storePassword=SENHA_DO_KEYSTORE
   keyPassword=SENHA_DA_CHAVE
   keyAlias=ALIAS_DA_CHAVE
   storeFile=C:/CAMINHO/SEGURO/upload-keystore.jks
   ```

4. Gere o pacote Android App Bundle com `flutter build appbundle --release`.
   A build de release falha intencionalmente se a configuração de assinatura
   estiver ausente; ela nunca usa a chave de debug.
5. No Play Console, prepare uma ficha de loja original (nome, descrição,
   ícone, capturas de tela e imagem promocional), política de privacidade
   hospedada publicamente, classificação etária, formulário de segurança de
   dados e demais declarações aplicáveis. Informe também um contato de suporte.
6. Envie `build/app/outputs/bundle/release/app-release.aab` para uma faixa de
   teste, valide em aparelhos reais e conclua os requisitos de teste da conta
   antes de solicitar a produção.

Uma build assinada não publica automaticamente o aplicativo. O envio e a
liberação requerem uma conta de desenvolvedor Google Play e acesso ao Play
Console. Antes de cada atualização, incremente a versão e o `versionCode` em
`pubspec.yaml`.
