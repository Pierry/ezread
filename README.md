# zread

Leitor de Markdown para macOS. Abre uma pasta pelo terminal e mostra os arquivos
como artigos. Editar é secundário: um atalho alterna para o texto cru.

Site: <https://pierry.github.io/zread/>

## Instalar

```sh
brew install pierry/zread/zread
```

O Homebrew compila o app na sua máquina e já deixa o comando `zread` no `PATH`.
Requer macOS 14 ou superior e as ferramentas de compilação Swift (Xcode).

### Por que compila?

O zread ainda não tem assinatura Developer ID nem notarização da Apple. Um app
compilado na sua máquina não recebe a marca de quarentena, então o macOS abre sem
aviso. Se você copiar o `.app` de outra pessoa ou baixar pronto, o macOS bloqueia
e dá para liberar com:

```sh
xattr -dr com.apple.quarantine zread.app
```

Rode isso só em um app de origem em que você confia.

## Usar

```sh
zread .
zread docs/design.md
```

| Atalho | Ação |
| --- | --- |
| `Cmd+E` | Alterna entre leitura e texto cru |
| `Cmd+S` | Salva |
| `Cmd+\` | Mostra ou oculta o menu lateral |
| `Cmd+,` | Abre os ajustes de leitura |
| `Cmd+O` | Abre outra pasta ou arquivo |

O menu lateral tem os arquivos e os ajustes: fonte, tamanho, espaço entre letras,
altura da linha e cor primária.

O documento recarrega ao focar a janela, se o arquivo mudou no disco.

HTML cru dentro do Markdown e imagens remotas não são exibidos, porque o conteúdo
de um repositório não é confiável e o app não usa sandbox.

## Desenvolver

```sh
swift test
scripts/bundle.sh
open build/zread.app
scripts/measure.sh
```

O design está em [docs/designs/zread.md](docs/designs/zread.md).

## Licença

MIT. Componentes de terceiros, com licenças em `Resources/vendor/`:

- [cmark-gfm](https://github.com/swiftlang/swift-cmark), via Swift Package Manager
- [highlight.js](https://highlightjs.org/), BSD-3-Clause
- [Source Serif Pro](https://github.com/adobe-fonts/source-serif), SIL Open Font License 1.1
