import { chromium } from 'playwright';
import fs from 'fs';

const browser = await chromium.launch({ headless: false });
const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const page = await context.newPage();

// 监听所有网络请求和响应
page.on('request', req => console.log('>>>', req.method(), req.url()));
page.on('response', res => console.log('<<<', res.status(), res.url()));

// 监听控制台日志
page.on('console', msg => console.log('CONSOLE:', msg.text()));

// 监听页面错误
page.on('pageerror', err => console.log('PAGE ERROR:', err.message));

await page.goto('http://112.213.108.32:12266/snake/#/pages/shares/creatOrder?type=0&code=300204.sz', { 
  waitUntil: 'networkidle', 
  timeout: 30000 
});

console.log('页面已加载:', page.url());
await page.waitForTimeout(2000);

// 获取买入价格和买入手数的初始值
const getValues = async () => {
  return await page.evaluate(() => {
    const priceInput = document.querySelector('input[type="number"]');
    const lotsInput = [...document.querySelectorAll('input[type="number"]')].find(inp => {
      const label = inp.closest('.uni-input')?.previousElementSibling?.textContent || '';
      return label.includes('手数') || label.includes('买入');
    });
    const payable = [...document.querySelectorAll('*')].find(el => 
      el.textContent?.includes('应付') || el.textContent?.includes('Amount Payable')
    )?.textContent || '';
    
    return {
      price: priceInput?.value || '',
      lots: lotsInput?.value || '',
      payable: payable.trim(),
    };
  });
};

console.log('\n=== 初始状态 ===');
let state = await getValues();
console.log('买入价格:', state.price);
console.log('买入手数:', state.lots);
console.log('应付金额:', state.payable);
await page.screenshot({ path: 'before_click.png', fullPage: true });

// 查找所有仓位按钮
const positionButtons = await page.evaluate(() => {
  const all = [...document.querySelectorAll('*')];
  const buttons = all.filter(el => {
    const text = el.textContent?.trim();
    return text === '1/4' || text === '1/3' || text === '1/2' || text === '全仓';
  });
  return buttons.map((btn, i) => ({
    index: i,
    text: btn.textContent.trim(),
    tag: btn.tagName,
    class: btn.className,
    parent: btn.parentElement?.tagName + '.' + (btn.parentElement?.className?.split(' ')[0] || ''),
    hasClick: !!(btn.onclick || btn.getAttribute('onclick') || btn.getAttribute('@click')),
  }));
});

console.log('\n=== 仓位按钮 ===');
positionButtons.forEach(b => console.log(`  [${b.index}] "${b.text}" <${b.tag}> class="${b.class}" parent="${b.parent}" hasClick=${b.hasClick}`));

// 尝试点击每个仓位按钮
for (const btnInfo of positionButtons) {
  console.log(`\n=== 点击 "${btnInfo.text}" ===`);
  
  // 获取按钮元素
  const btn = await page.evaluateHandle((text) => {
    const all = [...document.querySelectorAll('*')];
    return all.find(el => el.textContent?.trim() === text);
  }, btnInfo.text);
  
  if (btn) {
    // 点击前状态
    const before = await getValues();
    console.log('点击前 - 手数:', before.lots, '应付:', before.payable);
    
    // 点击
    await btn.asElement().click();
    await page.waitForTimeout(1000);
    
    // 点击后状态
    const after = await getValues();
    console.log('点击后 - 手数:', after.lots, '应付:', after.payable);
    
    // 截图
    await page.screenshot({ path: `after_${btnInfo.text.replace('/', '_')}.png`, fullPage: true });
    
    // 检查是否有网络请求
    console.log('等待网络请求...');
    await page.waitForTimeout(2000);
  } else {
    console.log('按钮未找到');
  }
}

// 检查页面上的事件监听器
const eventListeners = await page.evaluate(() => {
  const all = [...document.querySelectorAll('*')];
  const withEvents = all.filter(el => {
    const text = el.textContent?.trim();
    return (text === '1/4' || text === '1/3' || text === '1/2' || text === '全仓') &&
           (el.onclick || el.getAttribute('onclick') || el.getAttribute('@click') || 
            el.getAttribute('@tap') || el.getAttribute('@touchstart'));
  });
  return withEvents.map(el => ({
    text: el.textContent.trim(),
    onclick: el.onclick ? 'has onclick' : '',
    attr: el.getAttribute('onclick') || el.getAttribute('@click') || el.getAttribute('@tap') || '',
  }));
});

console.log('\n=== 有事件监听的元素 ===');
eventListeners.forEach(e => console.log(`  "${e.text}" onclick=${e.onclick} attr="${e.attr}"`));

// 获取完整的页面 JavaScript 代码片段（如果有内联脚本）
const scripts = await page.evaluate(() => {
  return [...document.querySelectorAll('script')].map(s => ({
    src: s.src || 'inline',
    content: s.textContent?.substring(0, 500) || '',
  }));
});

console.log('\n=== 页面脚本 ===');
scripts.forEach((s, i) => console.log(`  [${i}] ${s.src}: ${s.content.substring(0, 200)}`));

console.log('\n=== 测试完成，浏览器保持打开 ===');
await new Promise(r => setTimeout(r, 600000));
