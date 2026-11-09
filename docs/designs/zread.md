# zread

*   **Author:** Pierry Borges
*   **Status:** Draft
*   **Date:** 2026-11-08

--------------------------------------------------------------------------------

## Overview

zread é um app para macOS que abre uma pasta de projeto pelo terminal
(`zread .`) e mostra os arquivos Markdown dela como artigos para ler. A tela
padrão é o texto renderizado em uma coluna, com tipografia e componentes
inspirados na leitura do Medium. Editar existe, mas é secundário: um atalho
troca a tela para o texto cru, e outro salva.

A relação com o Zed é invertida. O Zed abre em código e pode mostrar um preview.
O zread abre na leitura e pode mostrar o código fonte do Markdown.

## The Problem

Markdown de repositório (README, `docs/`, design docs) é lido hoje dentro de
editores de código. Nesses editores o preview é um painel secundário: a
tipografia não foi pensada para texto longo, e árvore, abas e demais controles
do editor ficam em volta do texto.

Ajustar isso dentro do editor resolve só uma parte. O VS Code aceita CSS próprio
no preview (`markdown.styles`), o que melhora a tipografia, mas o preview
continua sendo um painel dentro de um editor. O zread só se justifica pelo que
um tema não entrega: uma janela feita só para ler, aberta direto do terminal, em
que o texto renderizado é a tela inicial.

Critério de corte para todo o projeto: **feature que não melhora a leitura de
Markdown de repositório fica fora.** A edição entra como exceção declarada, para
corrigir o que se percebe durante a leitura.

## Goals

**Abertura**

*   `zread .` abre a pasta atual, e `zread caminho/arquivo.md` abre direto
    naquele arquivo.
*   Ao abrir uma pasta, o primeiro arquivo mostrado é o `README.md` da raiz. Sem
    README, a tela mostra a árvore de arquivos.

**Leitura**

*   O modo leitura é sempre o modo inicial, para todo arquivo aberto.
*   O texto fica em uma coluna central de largura limitada, em torno de 680 px.
*   Tabelas e blocos de código largos não quebram a coluna do texto: rolam na
    horizontal dentro do próprio bloco.
*   Componentes renderizados: título, subtítulo, parágrafo, citação, lista,
    imagem, link, tabela, bloco de código com destaque de sintaxe, código
    inline, separador e task list.
*   Interface mínima: menu lateral recolhível por um botão na barra de título,
    com a árvore de arquivos e os ajustes. Nada de abas ou barra de ferramentas.

**Navegação no repositório**

*   A árvore lista só as pastas que contêm Markdown.
*   Pastas `.git`, `node_modules` e as listadas no `.gitignore` não aparecem.
*   Link relativo entre arquivos Markdown abre o destino dentro do zread.
    Âncoras (`#secao`) rolam até o título. Link externo abre no navegador padrão.
*   Imagem com caminho relativo é carregada do repositório.

**Edição (secundária)**

*   `Cmd+E` alterna entre leitura e texto cru. `Cmd+S` salva.
*   Ao alternar, a tela mantém o trecho que estava sendo lido, nos dois sentidos.
*   Nenhuma alteração não salva é perdida sem aviso, ao trocar de arquivo ou
    fechar a janela.

**Tema**

*   Modo claro: fundo Cloud Dancer (PANTONE 11-4201, `#F0EEE9`) com texto quase
    preto.
*   Modo escuro: fundo bem escuro, próximo do preto, com texto branco.
*   O tema acompanha a aparência do macOS.
*   Corpo em Source Serif Pro, embarcada no app (licença SIL OFL). Títulos e
    interface em Helvetica Neue, do sistema. Código sempre em Menlo.
*   Ajustes de leitura no menu lateral, aplicados na hora e guardados entre
    sessões: fonte (serifada ou monoespaçada), tamanho, espaço entre letras, altura
    da linha e cor primária, usada em títulos, links, citações e separadores.

**Leveza (metas propostas, ainda não medidas)**

*   Do Enter em `zread .` até o texto na tela: até 500 ms em Apple Silicon, com o
    app fechado.
*   App instalado: até 30 MB.
*   Memória com um documento aberto: até 200 MB, somando todos os processos do
    app.

## Non-Goals

*   Ser editor de código, ou abrir arquivos que não sejam Markdown.
*   Edição WYSIWYG ou por bloco.
*   Vault de notas: wikilinks, backlinks, grafo, tags.
*   Busca em todo o repositório na primeira versão.
*   Abas ou vários documentos lado a lado.
*   Temas configuráveis além dos ajustes de leitura listados nos Goals.
*   Plugins, sincronização, publicação ou exportação.
*   Windows e Linux.
*   Renderizar Mermaid ou matemática na primeira versão.
*   Reproduzir a marca do Medium: logo, nome, e recursos sociais como aplausos,
    comentários e perfil. A referência é só a experiência de leitura.

## Open Questions

Nenhuma em aberto. Decisões tomadas durante a redação:

*   **Fonte de título**: Helvetica Neue. A Söhne, associada ao Medium, é
    licenciada e não está nesta máquina.
*   **Modo escuro**: fundo `#0A0A0A`, texto `#FFFFFF`, a pedido do autor. Branco
    puro em texto longo pode ofuscar. Os valores ficam em variáveis CSS, e o
    teste de leitura real pode ajustá-los.
*   **Mudança no disco**: ao focar a janela, o app compara a data de modificação
    e recarrega mantendo o trecho. Com edição não salva, não recarrega. `Cmd+S`
    pede confirmação se o arquivo mudou no disco.
*   **Mermaid e matemática**: fora da v1. O bloco aparece como código.
*   **Arquivo muito grande**: acima de 2 MB, renderiza sem destaque de sintaxe, e
    as metas de abertura deixam de valer.

## Critical User Journeys (CUJs)

### CUJ 1: Ler os docs de um projeto

*   **Given**: um terminal em uma pasta de repositório com `README.md` e `docs/`.
*   **When**: o usuário executa `zread .` e clica em um link relativo no README.
*   **Then**: o README aparece em modo leitura, e o documento apontado abre na
    mesma janela, também em modo leitura.

### CUJ 2: Corrigir um erro durante a leitura

*   **Given**: um documento aberto em modo leitura, rolado até o meio.
*   **When**: o usuário tecla `Cmd+E`, corrige o texto, tecla `Cmd+S` e `Cmd+E`.
*   **Then**: o arquivo em disco contém a correção, e a leitura volta ao mesmo
    trecho já com o texto corrigido.

### CUJ 3: Ler à noite

*   **Given**: o macOS em aparência escura.
*   **When**: o usuário abre qualquer documento.
*   **Then**: o documento aparece com fundo bem escuro e texto branco, sem ajuste
    manual.

## Technical Plan (Architecture)

zread é um app AppKit em Swift, sem sandbox, distribuído fora da App Store. Ele
converte Markdown em HTML com cmark-gfm e mostra o resultado em uma única
`WKWebView`. O modo fonte é um `NSTextView` de texto simples, colocado no lugar
da WebView.

```text
terminal: zread .
   |
   v
CLI (zread)  -- caminho absoluto -->  open -b <bundle id> <caminho>
                                         |
                                         v
                              AppDelegate / WindowController
                              (uma janela por raiz aberta)
                                 |                    |
                     1. documento inicial     2. depois do primeiro texto
                                 v                    v
                         MarkdownRenderer        RepoScanner
                          (cmark-gfm)        (git ls-files ou varredura)
                                 |                    |
                                 v                    v
                         ReaderView (WKWebView)   FileTree (sidebar)
                          |            ^
          clique em link  |            | zread:// (imagens, CSS, JS)
                          v            |
                     LinkRouter    LocalScheme (só dentro da raiz)

Cmd+E:  ReaderView <--> SourceEditor (NSTextView), trocando número de linha
Cmd+S:  SourceEditor --> grava no disco --> MarkdownRenderer --> ReaderView
```

### Linha de base medida

Um protótipo descartável (janela AppKit, uma `WKWebView`, 400 seções de HTML
sintético, sem parser) foi executado 5 vezes em 2026-11-08:

| Item | Resultado |
| --- | --- |
| Texto carregado, execuções 2 a 5 | 226 a 265 ms |
| Texto carregado, primeira execução | 1.624 ms |
| Memória somada (app + processos WebKit) | 175 a 176 MB |
| Binário | 109 KB |
| Ghostty, para comparação | 62 MB em disco, 153 MB rodando com sessões abertas |
| Zed, para comparação | 176 MB em disco, memória não medida |

A memória soma RSS, que conta páginas compartilhadas do sistema mais de uma vez,
então o valor real é menor. Restam cerca de 25 MB até a meta de 200 MB antes de
somar parser, CSS e imagens. A meta de 500 ms vale para abertura com o WebKit já
em cache de disco. A primeira execução depois de um boot pode passar dela.

### Componentes

*   **CLI `zread`**: binário pequeno dentro do bundle. Resolve o argumento para
    caminho absoluto e pede ao macOS para abrir o app com ele, via `open -b`.
    Repetir o comando com o app aberto reaproveita a instância em execução. O
    comando chega ao `PATH` por symlink em `/usr/local/bin`, criado por um item
    de menu do app.
*   **WindowController**: uma janela por pasta raiz. Reabrir a mesma raiz traz a
    janela existente para a frente.
*   **MarkdownRenderer**: chama cmark-gfm com as extensões de tabela, task list,
    strikethrough e autolink, e com a opção de posição de origem, que grava a
    linha de cada bloco em `data-sourcepos`. Entrega um fragmento HTML.
*   **ReaderView**: reaproveita a mesma `WKWebView`, trocando só o conteúdo. A
    casca de página, o CSS e o JS vêm do bundle.
*   **Tema**: um CSS com variáveis de cor, trocadas por
    `prefers-color-scheme`. Fontes do sistema, nenhuma embarcada.
*   **Destaque de sintaxe**: highlight.js embarcado, com linguagens comuns,
    carregado só quando o documento tem bloco de código.
*   **RepoScanner**: em repositório git, usa `git ls-files -co
    --exclude-standard` filtrando `*.md` e `*.markdown`, o que já respeita o
    `.gitignore`. Fora de git, percorre a pasta ignorando `.git` e
    `node_modules`. Roda depois do primeiro texto, para não atrasar a abertura.
*   **LocalScheme**: `WKURLSchemeHandler` para `zread://`. Serve imagens
    relativas à raiz e recusa qualquer caminho que, resolvido, saia dela.
*   **LinkRouter**: decide cada navegação da WebView. Arquivo Markdown dentro da
    raiz abre no zread, `#ancora` rola na página, e `http(s)` e `mailto` vão para
    o sistema.
*   **SourceEditor**: `NSTextView` em texto simples, Menlo, sem destaque. Guarda
    o estado de alteração não salva e pede confirmação ao trocar de arquivo ou
    fechar.

### Alternância mantendo o trecho

*   **Leitura para fonte**: um script acha o primeiro bloco visível, lê a linha
    em `data-sourcepos` e o `NSTextView` rola até essa linha.
*   **Fonte para leitura**: o app pega a primeira linha visível, renderiza de
    novo se houve mudança, e o script rola até o último bloco cuja linha inicial
    é menor ou igual a ela.

A precisão é por bloco. Um parágrafo longo volta ao seu início, não à frase
exata.

### Segurança

Arquivos de um repositório clonado são conteúdo não confiável, e o app não tem
sandbox. Por isso:

*   HTML cru dentro do Markdown é descartado, que é o modo padrão do cmark. O
    custo é real: READMEs com `<img>` de largura definida, `<details>` ou
    alinhamento em HTML perdem esses elementos.
*   Uma Content-Security-Policy permite script, estilo e imagem apenas de
    `zread://`. Imagens remotas ficam bloqueadas, o que evita que abrir um
    documento avise um servidor externo, e também significa que badges de README
    não aparecem.
*   `LocalScheme` restringe a leitura à raiz aberta.

## Alternatives Considered

Não houve brief prévio. Estas alternativas vieram da discussão durante a
redação. Apenas a WKWebView foi medida. Os demais números são estimativas.

### Alternativa A: Tema CSS no preview de um editor existente

*   **Pros**: quase nenhum código. O VS Code aceita CSS próprio pela configuração
    `markdown.styles`.
*   **Cons**: o preview continua sendo um painel dentro de um editor, e não abre
    direto em leitura pelo terminal.
*   **Reason for Rejection**: Rejected by author: a dor escolhida é o preview ser
    secundário dentro de um editor, e um tema muda só a tipografia.

### Alternativa B: Nativo com TextKit, sem WebView

*   **Pros**: elimina os processos WebKit, cerca de 76 MB medidos no protótipo.
    App estimado entre 3 e 8 MB.
*   **Cons**: tabela, bloco de código com rolagem própria e imagem exigem views
    embutidas feitas à mão, e cada componente vira código próprio.
*   **Reason for Rejection**: Rejected by author: a WKWebView mediu 175 MB, na
    faixa dos 153 MB do Ghostty em uso, e entrega os componentes por CSS. A
    economia de memória não paga o trabalho por componente.

### Alternativa C: GPUI, o framework de interface do Zed

*   **Pros**: mesma técnica do Zed, desenho direto na GPU, sem WebView.
*   **Cons**: todos os componentes de leitura, seleção de texto e imagens seriam
    escritos do zero, sobre uma dependência sujeita a mudança de API. Não medido.
*   **Reason for Rejection**: Rejected by author: o renderizador do Zed é feito
    para editar código, e a leitura deste produto não precisa dele.

### Alternativa D: Tauri (Rust com WebView do sistema)

*   **Pros**: ecossistema Rust, app estimado entre 10 e 15 MB.
*   **Cons**: usa a mesma WebView, então não reduz memória, e acrescenta uma
    ponte Rust/JS e custo no início.
*   **Reason for Rejection**: retirada da lista de opções durante a redação, antes
    da escolha final do autor: tem o custo da WKWebView e mais uma camada, sem
    ganho em leveza.

### Alternativa E: Electron

*   **Pros**: ecossistema web completo e Chromium previsível.
*   **Cons**: embarca um navegador inteiro no app.
*   **Reason for Rejection**: não chegou a ser opção: incompatível com a meta de
    até 30 MB aprovada pelo autor.

### Alternativa F: Edição por bloco

*   **Pros**: corrige um trecho sem sair do ponto de leitura.
*   **Cons**: o parser precisa mapear bloco para linhas do arquivo, e limites de
    bloco são ambíguos em lista aninhada e tabela.
*   **Reason for Rejection**: Rejected by author: edição é secundária, e o modo
    alternado mantém a leitura separada e simples.

### Alternativa G: WYSIWYG

*   **Pros**: o usuário nunca vê sintaxe de Markdown.
*   **Cons**: exige um motor de edição completo, e serializar de volta pode
    reformatar o arquivo, gerando diff de ruído no repositório.
*   **Reason for Rejection**: Rejected by author: mesmo motivo da Alternativa F,
    somado ao peso contra a meta de leveza.

### Alternativa H: Escopo de vault de notas ou de arquivo único

*   **Pros**: vault atenderia notas pessoais, e arquivo único seria o app mais
    simples possível.
*   **Cons**: vault exige índice e wikilinks e compete com o Obsidian. Arquivo
    único perde a navegação entre documentos.
*   **Reason for Rejection**: Rejected by author: o cenário escolhido é ler docs
    de repositório.

--------------------------------------------------------------------------------

## Detailed Implementation Plan

Projeto novo: o diretório está vazio e não é repositório git. Todos os arquivos
são criados. Requisitos: macOS 14 ou superior, Swift Package Manager, bundle id
`com.pierryborges.zread`, app sem sandbox. Única dependência externa de código:
`swift-cmark` (branch `gfm`, de `swiftlang/swift-cmark`).

### Target Files to Create/Modify

#### 1. `./Package.swift` (Create)

*   **Type / Scope**: Build.
*   **Proposed Changes**: Alvos executáveis `ZreadApp` e `zread-cli`, alvo de
    biblioteca `ZreadCore` para a lógica testável, alvo de teste, e dependência
    em `swift-cmark`. Separar `ZreadCore` permite testar sem abrir janela.

#### 2. `./Sources/ZreadCore/MarkdownRenderer.swift` (Create)

*   **Type / Scope**: Biblioteca.
*   **Proposed Changes**: `render(markdown: String) -> RenderedDocument`, com o
    HTML e a informação `hasCode`. Usa cmark-gfm com tabela, task list,
    strikethrough, autolink e posição de origem. Sem a opção unsafe, para
    descartar HTML cru. Reescreve `src` de imagens relativas para `zread://`.

#### 3. `./Sources/ZreadCore/RepoScanner.swift` (Create)

*   **Type / Scope**: Biblioteca.
*   **Proposed Changes**: `scan(root: URL) async -> [FileNode]`. Com `.git` na
    raiz, roda `git ls-files -co --exclude-standard`. Sem git ou com falha do
    comando, percorre a pasta ignorando `.git` e `node_modules`. Filtra `.md` e
    `.markdown`, e devolve árvore só com pastas que contêm esses arquivos.

#### 4. `./Sources/ZreadCore/RootResolver.swift` (Create)

*   **Type / Scope**: Biblioteca.
*   **Proposed Changes**: A partir do argumento, devolve `root` e arquivo
    inicial. Pasta: é a raiz, com `README.md` como inicial, se existir. Arquivo:
    sobe até achar `.git`, ou usa a pasta do arquivo como raiz.

#### 5. `./Sources/ZreadCore/PathGuard.swift` (Create)

*   **Type / Scope**: Biblioteca, segurança.
*   **Proposed Changes**: `resolve(request:, root:) -> URL?`. Resolve symlinks e
    `..`, e devolve nulo se o resultado sair da raiz. Usado por `LocalScheme` e
    `LinkRouter`.

#### 6. `./Sources/ZreadCore/LinkClassifier.swift` (Create)

*   **Type / Scope**: Biblioteca.
*   **Proposed Changes**: Classifica link em `internalMarkdown`, `anchor`,
    `external` ou `blocked`, sem depender de AppKit. Só `http`, `https` e
    `mailto` são externos.

#### 7. `./Sources/ZreadCore/DocumentSession.swift` (Create)

*   **Type / Scope**: Biblioteca.
*   **Proposed Changes**: Guarda caminho, texto, data de modificação carregada e
    estado de alteração não salva. Expõe `load()`, `save()`, que sinaliza
    conflito se o disco mudou, e `changedOnDisk()`. Salva por escrita atômica.

#### 8. `./Sources/ZreadApp/main.swift` e `./Sources/ZreadApp/AppDelegate.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Inicialização e `application(_:open:)`, que recebe os
    caminhos e encaminha para a janela daquela raiz. Menu com `Cmd+E`, `Cmd+S` e
    o item de instalar o comando. A checagem de disco é disparada ao focar.

#### 9. `./Sources/ZreadApp/WindowController.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Uma janela por raiz. Monta sidebar recolhível, área de
    conteúdo e a troca entre `ReaderView` e `SourceEditor`. Pede confirmação ao
    fechar ou trocar de arquivo com alteração não salva.

#### 10. `./Sources/ZreadApp/ReaderView.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Embrulha a `WKWebView`. Carrega a casca uma vez e troca
    o conteúdo por script. Expõe `topVisibleLine()` e `scrollTo(line:)`.

#### 11. `./Sources/ZreadApp/SourceEditor.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: `NSTextView` em texto simples com Menlo, sem
    substituições automáticas de aspas ou traços. Expõe as mesmas operações de
    linha do `ReaderView`.

#### 12. `./Sources/ZreadApp/FileTreeView.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: `NSOutlineView` alimentado pelo `RepoScanner`. Mostra a
    árvore assim que a varredura termina, sem bloquear o primeiro texto.

#### 13. `./Sources/ZreadApp/LocalScheme.swift` e `./Sources/ZreadApp/LinkRouter.swift` (Create)

*   **Type / Scope**: App, segurança.
*   **Proposed Changes**: `LocalScheme` serve recursos do bundle e imagens da
    raiz por `PathGuard`. `LinkRouter` aplica `LinkClassifier` em cada navegação
    da WebView, e bloqueia as demais.

#### 14. `./Sources/ZreadApp/CLIInstaller.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Cria o symlink `/usr/local/bin/zread` para o binário do
    bundle. Sem permissão, mostra o comando para o usuário rodar.

#### 15. `./Sources/zread-cli/main.swift` (Create)

*   **Type / Scope**: CLI.
*   **Proposed Changes**: Resolve o argumento (padrão `.`) para caminho absoluto
    e chama `open -b com.pierryborges.zread`. Caminho inexistente gera erro em
    stderr e saída 1.

#### 16. `./Resources/page.html` (Create)

*   **Type / Scope**: Interface.
*   **Proposed Changes**: Casca da página, com a Content-Security-Policy que só
    permite `zread://`.

#### 17. `./Resources/reader.css` (Create)

*   **Type / Scope**: Interface.
*   **Proposed Changes**: Variáveis de cor para claro (`#F0EEE9`) e escuro
    (`#0A0A0A` e `#FFFFFF`), coluna em torno de 680 px, Charter no corpo,
    Helvetica Neue em títulos, Menlo em código. Estilos dos componentes listados
    nos Goals, com rolagem horizontal própria em tabela e bloco de código.

#### 18. `./Resources/reader.js` (Create)

*   **Type / Scope**: Interface.
*   **Proposed Changes**: Trocar conteúdo, ler o primeiro bloco visível por
    `data-sourcepos`, rolar até uma linha, gerar âncoras nos títulos e carregar o
    destaque de sintaxe só quando `hasCode` for verdadeiro.

#### 19. `./Resources/vendor/highlight.min.js` e `./Resources/vendor/highlight.css` (Create)

*   **Type / Scope**: Dependência embarcada.
*   **Proposed Changes**: Build de linguagens comuns do highlight.js, com versão
    fixada e cores ajustadas aos dois temas. Sem acesso à rede em execução.

#### 20. `./Resources/Info.plist` (Create)

*   **Type / Scope**: Configuração.
*   **Proposed Changes**: Bundle id e tipos de documento para pasta e Markdown,
    necessários para o macOS entregar os caminhos ao app.

#### 21. `./scripts/bundle.sh` (Create)

*   **Type / Scope**: Build.
*   **Proposed Changes**: Compila em release, monta `zread.app` com os dois
    binários e `Resources`, e assina ad hoc.

#### 22. `./scripts/measure.sh` e `./Tests/fixtures/long.md` (Create)

*   **Type / Scope**: Medição.
*   **Proposed Changes**: Executa o app com o documento de teste e registra tempo
    até o texto, memória somada dos processos e tamanho do bundle, para comparar
    com as metas.

#### 23. `./Tests/ZreadCoreTests/*.swift` (Create)

*   **Type / Scope**: Testes de unidade.
*   **Proposed Changes**: Um arquivo por tipo de `ZreadCore`: HTML cru descartado
    e `data-sourcepos` presente; `.gitignore` respeitado e fallback sem git;
    raiz resolvida de pasta e de arquivo; caminho com `..` e symlink recusados;
    classificação de cada tipo de link; conflito ao salvar.

#### 24. `./README.md` e `./.gitignore` (Create)

*   **Type / Scope**: Documentação e repositório.
*   **Proposed Changes**: Como compilar, instalar o comando e usar. Ignora
    `.build` e o app gerado.

### Verification Plan

*   **Compilation/Build**: `swift build -c release` e `scripts/bundle.sh`.
*   **Unit Tests**: `swift test`.
*   **Static Analysis & Linting**: compilação sem warnings.
*   **Test Coverage Requirement**: toda a lógica de `PathGuard`, `LinkClassifier`
    e `DocumentSession.save`. Os demais tipos de `ZreadCore` pelos casos acima.
*   **E2E/Integration**: executar os três CUJs à mão em um repositório real. Abrir
    documento malicioso com `<script>`, imagem remota e link `../../` e confirmar
    que nada executa, carrega ou sai da raiz.
*   **Performance**: `scripts/measure.sh`, 5 execuções, com as metas de 500 ms,
    30 MB e 200 MB. Registrar a primeira execução em separado.

--------------------------------------------------------------------------------

*Drafted with EGM*
