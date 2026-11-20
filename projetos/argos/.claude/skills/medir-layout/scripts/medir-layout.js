window.argosLayout = (() => {
    const ALTURA_CAMPO = 36;
    const ALTURA_BOTAO = 32;
    const espera = (ms) => new Promise((resolver) => setTimeout(resolver, ms));
    const itensMenu = () => [...document.querySelectorAll('nav .MuiListItemButton-root')];

    async function irPara(grupo, item) {
        let alvo = itensMenu().find((x) => x.textContent.trim() === item);
        if (!alvo) {
            itensMenu().find((x) => x.textContent.trim().toUpperCase() === grupo.toUpperCase())?.click();
            await espera(400);
            alvo = itensMenu().find((x) => x.textContent.trim() === item);
        }
        alvo?.click();
        await espera(2300);
        return !!alvo;
    }

    async function fecharAvisosIniciais() {
        for (const texto of ['Seguir sem importar', 'Fechar']) {
            [...document.querySelectorAll('.MuiDialog-root button')].find((b) => b.textContent.trim().includes(texto))?.click();
            await espera(400);
        }
    }

    function tintaDoTexto(entrada) {
        const raiz = entrada.closest('.MuiInputBase-root, .MuiPickersInputBase-root');
        const estilo = getComputedStyle(entrada);
        const contexto = document.createElement('canvas').getContext('2d');
        contexto.font = `${estilo.fontWeight} ${estilo.fontSize} ${estilo.fontFamily}`;
        const metricas = contexto.measureText('Implantação');
        const maiuscula = contexto.measureText('H');
        const caixa = entrada.getBoundingClientRect();
        const alturaLinha = parseFloat(estilo.height) || 20;
        const topo = caixa.top + parseFloat(estilo.paddingTop);
        const base = topo + (alturaLinha - (metricas.fontBoundingBoxAscent + metricas.fontBoundingBoxDescent)) / 2 + metricas.fontBoundingBoxAscent;
        const borda = raiz.getBoundingClientRect();
        return { acima: base - maiuscula.actualBoundingBoxAscent - borda.top, abaixo: borda.bottom - base };
    }

    function rotuloDe(raiz) {
        return (raiz.parentElement.querySelector('label')?.textContent || raiz.querySelector('input')?.placeholder || '?').slice(0, 24);
    }

    function medir(raiz = document.querySelector('.MuiDialog-paper:last-of-type') ?? document.querySelector('main')) {
        const problemas = [];
        let campos = 0;
        raiz.querySelectorAll('.MuiInputBase-root, .MuiPickersInputBase-root').forEach((campo) => {
            if (campo.closest('.MuiTablePagination-root')) return;
            const borda = campo.getBoundingClientRect();
            if (borda.height === 0) return;
            campos++;
            const rotulo = rotuloDe(campo);
            const multilinha = campo.classList.contains('MuiInputBase-multiline') || campo.querySelector('.ProseMirror');
            if (!multilinha && Math.round(borda.height) !== ALTURA_CAMPO) problemas.push(`${rotulo}: altura ${Math.round(borda.height)} (esperado ${ALTURA_CAMPO})`);
            campo.querySelectorAll('.MuiChip-root, .MuiInputAdornment-root > *:not(button)').forEach((item) => {
                const caixa = item.getBoundingClientRect();
                if (caixa.height < 8) return;
                const acima = caixa.top - borda.top;
                const abaixo = borda.bottom - caixa.bottom;
                if (Math.min(acima, abaixo) < 5 || Math.abs(acima - abaixo) > 1.5) problemas.push(`${rotulo}: badge/chip com folga ${Math.round(acima)}/${Math.round(abaixo)}`);
            });
            const entrada = campo.querySelector('input:not([type=hidden]):not([aria-hidden=true]), .MuiPickersSectionList-root');
            if (entrada && !multilinha) {
                const { acima, abaixo } = tintaDoTexto(entrada);
                if (Math.abs(acima - abaixo) > 1.5) problemas.push(`${rotulo}: texto fora do meio (maiúscula ${acima.toFixed(1)} / base ${abaixo.toFixed(1)})`);
            }
            const ajuda = campo.parentElement.querySelector('.MuiFormHelperText-root');
            if (ajuda && ajuda.textContent.trim() !== '') {
                const faixa = document.createRange();
                faixa.selectNodeContents(ajuda);
                const textoAjuda = faixa.getBoundingClientRect();
                const abaixoDela = [...raiz.querySelectorAll('.MuiFormControl-root label')]
                    .map((rotuloAbaixo) => { const r = document.createRange(); r.selectNodeContents(rotuloAbaixo); return r.getBoundingClientRect(); })
                    .filter((caixa) => caixa.top > textoAjuda.bottom - 1 && caixa.left < textoAjuda.right && caixa.right > textoAjuda.left)
                    .sort((a, b) => a.top - b.top)[0];
                if (abaixoDela && abaixoDela.top - textoAjuda.bottom < 3) problemas.push(`${rotulo}: texto de ajuda a ${(abaixoDela.top - textoAjuda.bottom).toFixed(1)} px do rótulo de baixo`);
            }
        });
        raiz.querySelectorAll('button.MuiButton-root, .MuiToggleButton-root').forEach((botao) => {
            const caixa = botao.getBoundingClientRect();
            if (caixa.height === 0 || botao.closest('.MuiAlert-action, .MuiPickersLayout-root')) return;
            const naLinhaDeCampo = [...(botao.parentElement?.parentElement?.children ?? []), ...(botao.parentElement?.children ?? [])]
                .some((irmao) => irmao !== botao && irmao.matches?.('.MuiFormControl-root, .MuiAutocomplete-root, .MuiPickersTextField-root'));
            const esperado = naLinhaDeCampo ? ALTURA_CAMPO : ALTURA_BOTAO;
            if (Math.round(caixa.height) !== esperado) problemas.push(`botão "${botao.textContent.trim().slice(0, 20)}": ${Math.round(caixa.height)} (esperado ${esperado})`);
            if (!botao.querySelector('.MuiButton-startIcon, .MuiButton-endIcon, svg') && botao.classList.contains('MuiButton-root')) problemas.push(`botão "${botao.textContent.trim().slice(0, 20)}" sem ícone`);
        });
        raiz.querySelectorAll('.barra-editor-texto').forEach((barra) => {
            const icones = [...barra.querySelectorAll('svg')].map((icone) => icone.getBoundingClientRect());
            if (icones.length === 0) return;
            const rotulo = barra.closest('.MuiFormControl-root')?.querySelector('label');
            let referencia = barra.getBoundingClientRect().top;
            if (rotulo) { const faixa = document.createRange(); faixa.selectNodeContents(rotulo); referencia = faixa.getBoundingClientRect().bottom; }
            const acima = Math.min(...icones.map((icone) => icone.top)) - referencia;
            const abaixo = barra.getBoundingClientRect().bottom - Math.max(...icones.map((icone) => icone.bottom));
            if (Math.abs(acima - abaixo) > 1.5) problemas.push(`barra do editor: ${acima.toFixed(1)} em cima / ${abaixo.toFixed(1)} embaixo`);
        });
        const titulo = raiz.querySelector('h5, h6, .MuiDialogTitle-root')?.textContent?.slice(0, 40) ?? '?';
        return { titulo, campos, problemas };
    }

    function menuLateral() {
        return itensMenu().map((item) => `${item.textContent.trim().slice(0, 18)}: ${Math.round(item.getBoundingClientRect().height)}`);
    }

    async function varrer(telas) {
        const resultado = [];
        for (const [grupo, item] of telas) {
            const achou = await irPara(grupo, item);
            resultado.push({ tela: `${grupo} → ${item}`, achou, ...medir(document.querySelector('main')) });
        }
        return resultado;
    }

    return { irPara, fecharAvisosIniciais, medir, menuLateral, varrer, espera };
})();
'carregado: argosLayout.medir(), argosLayout.varrer([[grupo, item], ...]), argosLayout.menuLateral()';
