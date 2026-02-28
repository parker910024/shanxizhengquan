import { chromium } from 'playwright';
import fs from 'fs';

// 只打开浏览器，用户手动操作，通过信号文件触发分析
const browser = await chromium.launch({ headless: false });
const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const page = await context.newPage();

await page.goto('http://112.213.108.32:12266/snake', { waitUntil: 'networkidle', timeout: 30000 });
console.log('浏览器已打开，请手动操作...');
console.log('操作完毕后，在项目目录创建 go.txt 文件触发分析');

// 轮询等待信号文件
const signalFile = 'go.txt';
while (!fs.existsSync(signalFile)) {
  await new Promise(r => setTimeout(r, 1000));
}
fs.unlinkSync(signalFile);

console.log('\n=== 开始分析当前页面 ===');
console.log('URL:', page.url());
console.log('Title:', await page.title());
await page.screenshot({ path: 'current_page.png', fullPage: true });
console.log('截图: current_page.png');

// 页面文字
const text = await page.evaluate(() => document.body.innerText);
console.log('\n--- 页面文字 ---');
console.log(text.substring(0, 3000));

// 所有按钮
const buttons = await page.evaluate(() => {
  return [...document.querySelectorAll('button, [role="button"], [class*="btn"], [class*="button"]')]
    .map(el => ({ text: el.innerText.trim().substring(0, 40), class: el.className.substring(0, 80), tag: el.tagName }));
});
console.log('\n--- 按钮 ---');
buttons.forEach((b, i) => console.log(`  [${i}] "${b.text}" class="${b.class}"`));

// 所有输入框
const inputs = await page.evaluate(() => {
  return [...document.querySelectorAll('input, select, textarea')]
    .map(el => ({ type: el.type, placeholder: el.placeholder, value: el.value, name: el.name, class: el.className.substring(0, 60) }));
});
console.log('\n--- 输入框 ---');
inputs.forEach((inp, i) => console.log(`  [${i}] type="${inp.type}" placeholder="${inp.placeholder}" value="${inp.value}"`));

// 所有文字块（仓位/手数/价格相关）
const labels = await page.evaluate(() => {
  return [...document.querySelectorAll('span, div, label, p')]
    .filter(el => {
      const t = el.innerText.trim();
      return t.length > 0 && t.length < 30 && 
        (t.includes('手') || t.includes('价') || t.includes('仓') || t.includes('余额') || 
         t.includes('买') || t.includes('卖') || t.includes('1/') || t.includes('全仓') ||
         t.includes('数量') || t.includes('金额') || t.match(/^\d/));
    })
    .map(el => ({ text: el.innerText.trim(), class: el.className.substring(0, 60), tag: el.tagName }));
});
console.log('\n--- 交易相关文字 ---');
labels.forEach((l, i) => console.log(`  [${i}] <${l.tag}> "${l.text}" class="${l.class}"`));

// 页面完整 DOM 结构（简化）
const structure = await page.evaluate(() => {
  const walk = (el, depth) => {
    if (depth > 5 || !el.children) return '';
    let result = '';
    for (const child of el.children) {
      const text = (child.childNodes.length === 1 && child.childNodes[0].nodeType === 3) 
        ? child.textContent.trim() : '';
      const hasClick = child.onclick || child.getAttribute('onclick') || child.getAttribute('@click');
      const cls = child.className?.toString().split(' ')[0] || '';
      if (text || hasClick || child.children.length > 0) {
        const prefix = '  '.repeat(depth);
        const info = [
          child.tagName.toLowerCase(),
          cls ? '.' + cls : '',
          text ? ` "${text}"` : '',
          hasClick ? ' [click]' : '',
        ].join('');
        if (text || hasClick) result += prefix + info + '\n';
        if (child.children.length > 0 && child.children.length < 20) {
          result += walk(child, depth + 1);
        }
      }
    }
    return result;
  };
  return walk(document.body, 0);
});
console.log('\n--- DOM 结构 ---');
console.log(structure.substring(0, 4000));

console.log('\n=== 分析完成 ===');

// 继续等待下一次信号
console.log('如需继续分析，再创建 go.txt');
while (true) {
  if (fs.existsSync(signalFile)) {
    fs.unlinkSync(signalFile);
    await page.screenshot({ path: `page_${Date.now()}.png`, fullPage: true });
    const t = await page.evaluate(() => document.body.innerText);
    console.log('\n=== 再次分析 ===');
    console.log('URL:', page.url());
    console.log(t.substring(0, 2000));
  }
  await new Promise(r => setTimeout(r, 1000));
}
