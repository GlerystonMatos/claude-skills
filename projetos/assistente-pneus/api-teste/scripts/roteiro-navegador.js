window.__esperar = (ms) => new Promise((r) => setTimeout(r, ms));
window.__campo = (rotulo) => [...document.querySelectorAll('label')].find((l) => l.textContent.replace('*', '').trim().startsWith(rotulo))?.parentElement.querySelector('input,textarea');
window.__digitar = async (elemento, texto) => {
    elemento.focus();
    const prototipo = elemento.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(prototipo, 'value').set.call(elemento, texto);
    elemento.dispatchEvent(new Event('input', { bubbles: true }));
};
window.__escolher = async (rotulo, texto, indice = 0) => {
    const campo = window.__campo(rotulo);
    if (!campo) return `campo ${rotulo} não achado`;
    await window.__digitar(campo, texto);
    for (let i = 0; i < 40; i++) {
        await window.__esperar(100);
        const opcoes = document.querySelectorAll('li[role=option]');
        if (opcoes.length > indice) { opcoes[indice].click(); await window.__esperar(300); return `ok ${campo.value}`; }
    }
    return `sem opções em ${rotulo}`;
};
window.__botao = async (texto) => {
    const botao = [...document.querySelectorAll('button,[role=button]')].find((b) => b.textContent.trim().startsWith(texto));
    if (!botao) return `botão ${texto} não achado`;
    botao.click();
    await window.__esperar(700);
    return `clicou ${texto}`;
};
window.__dump = async (nome) => {
    window.scrollTo(0, 0);
    await window.__esperar(100);
    const lista = [];
    for (const el of document.body.querySelectorAll('*')) {
        const r = el.getBoundingClientRect();
        if (!r.width && !r.height) continue;
        const c = getComputedStyle(el);
        if (c.visibility === 'hidden') continue;
        const texto = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).join(' ').trim();
        lista.push({ t: el.tagName, x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height), tx: texto.slice(0, 60), cor: c.color, fundo: c.backgroundColor, borda: `${c.borderTopWidth} ${c.borderTopStyle} ${c.borderTopColor}`, fonte: `${c.fontSize} ${c.fontWeight}` });
    }
    await fetch(`http://localhost:5301/dump?nome=${nome}`, { method: 'POST', body: JSON.stringify(lista) });
    return lista.length;
};
window.__requisicoes = async (nome) => {
    const texto = await (await fetch('http://localhost:5301/registro')).text();
    await fetch(`http://localhost:5301/dump?nome=${nome}`, { method: 'POST', body: texto });
    return JSON.parse(texto).length;
};
window.__clicarPosicao = async (texto, indice = 0) => {
    const botoes = [...document.querySelectorAll('button.MuiButtonBase-root:not([disabled])')].filter((b) => b.textContent.includes(texto) && b.querySelector('svg rect'));
    if (!botoes[indice]) return `posição ${texto} não achada`;
    botoes[indice].click();
    await window.__esperar(800);
    return `posição ${botoes[indice].textContent}`;
};
window.__fluxoMontagem = async (s, hodometro, buscaPneu = 'NV', confirmar = false) => {
    const r = [];
    await window.__requisicoes('lixo');
    r.push(await window.__escolher('Estabelecimento', 'Mat'));
    r.push(await window.__escolher('Depósito de pneus', 'D0'));
    r.push(await window.__escolher('Realizado por', 'Ma'));
    r.push(await window.__escolher('Veículo', 'ABC'));
    await window.__esperar(1200);
    if (hodometro !== undefined) { await window.__digitar(window.__campo('Hodômetro'), String(hodometro)); await window.__esperar(300); }
    r.push(await window.__dump(`f1-${s}`));
    r.push(await window.__botao('Avançar'));
    r.push(await window.__botao('Ver conjunto completo'));
    await window.__esperar(1500);
    r.push(await window.__dump(`f2-${s}`));
    r.push(await window.__clicarPosicao('Livre'));
    r.push(await window.__escolher('Selecione o pneu', buscaPneu));
    r.push(await window.__dump(`f3-${s}`));
    r.push(await window.__botao('Adicionar montagem'));
    r.push(await window.__dump(`f4-${s}`));
    r.push(await window.__botao('Avançar'));
    r.push(await window.__dump(`f5-${s}`));
    r.push(await window.__botao('Gravar movimentação'));
    await window.__esperar(1000);
    if (confirmar) { r.push(await window.__dump(`f6g-${s}`)); r.push(await window.__botao('Confirmar giro')); await window.__esperar(1000); }
    r.push(await window.__dump(`f6-${s}`));
    r.push(await window.__requisicoes(`freq-${s}`));
    return r;
};
window.__fluxoEdicao = async (s) => {
    const r = [];
    await window.__esperar(2500);
    r.push(await window.__dump(`e1-${s}`));
    r.push(await window.__botao('Avançar'));
    await window.__esperar(1500);
    r.push(await window.__dump(`e2-${s}`));
    r.push(await window.__botao('Avançar'));
    r.push(await window.__dump(`e3-${s}`));
    r.push(await window.__botao('Gravar movimentação'));
    await window.__esperar(800);
    r.push(await window.__dump(`e4-${s}`));
    r.push(await window.__botao('Concluir'));
    r.push(await window.__requisicoes(`ereq-${s}`));
    return r;
};
window.__fluxoDesmontagem = async (s) => {
    const r = [];
    scrollTo(0, 0);
    await window.__requisicoes('lixo');
    r.push(await window.__botao('Desmontagem'));
    r.push(await window.__escolher('Estabelecimento', 'Mat'));
    r.push(await window.__escolher('Realizado por', 'Ma'));
    r.push(await window.__escolher('Veículo', 'ABC'));
    await window.__esperar(1200);
    r.push(await window.__dump(`d1-${s}`));
    r.push(await window.__botao('Avançar'));
    r.push(await window.__botao('Ver conjunto completo'));
    await window.__esperar(1500);
    r.push(await window.__clicarPosicao('FG1003'));
    await window.__esperar(1200);
    r.push(await window.__dump(`d2-${s}`));
    r.push(await window.__escolher('Depósito de destino', 'D0'));
    r.push(await window.__escolher('Motivo da desmontagem', 'Des'));
    r.push(await window.__dump(`d3-${s}`));
    r.push(await window.__botao('Adicionar desmontagem'));
    r.push(await window.__dump(`d4-${s}`));
    r.push(await window.__botao('Avançar'));
    r.push(await window.__dump(`d5-${s}`));
    r.push(await window.__botao('Gravar movimentação'));
    await window.__esperar(1000);
    r.push(await window.__dump(`d6-${s}`));
    r.push(await window.__requisicoes(`dreq-${s}`));
    return r;
};
window.__fluxoErroPneu = async (s) => {
    const r = [];
    scrollTo(0, 0);
    r.push(await window.__escolher('Estabelecimento', 'Mat'));
    r.push(await window.__escolher('Depósito de pneus', 'D0'));
    r.push(await window.__escolher('Realizado por', 'Ma'));
    r.push(await window.__escolher('Veículo', 'ABC'));
    await window.__esperar(1200);
    r.push(await window.__botao('Avançar'));
    r.push(await window.__botao('Ver conjunto completo'));
    await window.__esperar(1500);
    r.push(await window.__clicarPosicao('Livre'));
    await window.__digitar(window.__campo('Selecione o pneu'), 'falha');
    await window.__esperar(1500);
    r.push(await window.__dump(`p1-${s}`));
    r.push([...document.querySelectorAll('[role=dialog] .MuiAlert-message')].map((a) => a.textContent).join(' | '));
    r.push(await window.__botao('Tentar novamente'));
    await window.__esperar(1200);
    r.push(await window.__dump(`p2-${s}`));
    await window.__digitar(window.__campo('Selecione o pneu'), 'N');
    await window.__esperar(900);
    r.push(await window.__dump(`p3-${s}`));
    r.push(await window.__requisicoes(`preq-${s}`));
    return r;
};
'roteiro carregado';
