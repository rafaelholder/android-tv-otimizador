# 2. Instalar o ADB

O ADB (*Android Debug Bridge*) é a ferramenta oficial do Google para conversar com aparelhos Android.

## Opção A: winget (recomendado)

No PowerShell:

```powershell
winget install --id Google.PlatformTools -e
```

Os scripts encontram o `adb.exe` sozinhos, mesmo que ele não esteja no PATH. Eles procuram em três lugares:

- no PATH;
- na pasta do winget (`%LOCALAPPDATA%\Microsoft\WinGet\Packages\Google.PlatformTools_*`);
- no Android SDK (`%LOCALAPPDATA%\Android\Sdk\platform-tools`).

## Opção B: download manual

1. Baixe o *SDK Platform-Tools for Windows* na página oficial: <https://developer.android.com/tools/releases/platform-tools>
2. Extraia, por exemplo, em `C:\platform-tools`.
3. Adicione essa pasta ao PATH, ou rode os scripts mesmo assim. Se não encontrarem o adb, eles avisam.

## Conferir

```powershell
adb version
```

Se aparecer "não é reconhecido", feche e abra o PowerShell de novo. Os scripts funcionam mesmo assim.

Próximo passo: [Otimizar](03-otimizar.md)
