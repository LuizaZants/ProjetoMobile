# 🚀 Tour — Como rodar (Windows)

---

## OPÇÃO 1 — Testar no Chrome agora (mais rápido)

### Pré-requisitos
- Flutter SDK instalado → https://flutter.dev/docs/get-started/install/windows
- Chrome instalado

### Comandos
```bash
# Na pasta do projeto:
flutter pub get
flutter run -d chrome
```

O app abre no Chrome em modo mobile. A localização usará São Paulo como padrão
se o navegador não permitir GPS — perfeito para demo.

> Para mudar a cidade padrão, edite `lib/services/LocaleService.dart`:
> linha `_defaultLat` e `_defaultLng`

---

## OPÇÃO 2 — Rodar no Android (apresentação final)

### Pré-requisitos
1. **Flutter SDK** → https://flutter.dev/docs/get-started/install/windows
2. **Android Studio** → https://developer.android.com/studio
   - Durante a instalação marque: ✅ Android SDK ✅ Android Virtual Device

### Ativar modo desenvolvedor no celular
1. Configurações → Sobre o telefone
2. Toque **7 vezes** em "Número de compilação"
3. Configurações → Opções do desenvolvedor → ative **Depuração USB**
4. Conecte o cabo USB → toque **Permitir** no celular

### Comandos
```bash
flutter pub get
flutter devices          # confirma que o celular aparece na lista
flutter run              # instala e abre no celular
```

---

## OPÇÃO 3 — Gerar APK para instalar sem cabo

```bash
flutter pub get
flutter build apk --release
```

O APK fica em:
```
build\app\outputs\flutter-apk\app-release.apk
```

Envie por **WhatsApp** ou **Google Drive** para o celular e instale.
> No celular: Configurações → Segurança → ative "Fontes desconhecidas"

---

## Subir para o Git

```bash
git init
git add .
git commit -m "Tour app - versão final"
git remote add origin https://github.com/SEU_USUARIO/tour-app.git
git push -u origin main
```

---

## Erros comuns

| Erro | Solução |
|------|---------|
| `flutter` não reconhecido | Adicione `C:\flutter\bin` no PATH e reinicie o CMD |
| Celular não aparece | Troque o cabo, reinstale driver do fabricante |
| `SDK not found` | Android Studio → SDK Manager → instale Android 13+ |
| Erro de licença | `flutter doctor --android-licenses` e aceite tudo |
| Build falha | `flutter clean` depois `flutter pub get` |
| Maps não carrega no Chrome | Verifique se a Maps JavaScript API está ativa no Google Cloud |

---

## Verificar instalação

```bash
flutter doctor
```
Todos os itens com ✅ = pronto!
