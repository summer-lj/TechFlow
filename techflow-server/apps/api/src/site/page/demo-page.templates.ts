const apiBase = '/api/v1';

export function getDemoPageHtml() {
  return `<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Backend Demo</title>
    <link rel="stylesheet" href="/demo/style.css" />
  </head>
  <body>
    <main class="page">
      <section class="hero">
        <p class="eyebrow">Development Flow Demo</p>
        <h1 id="hero-title">加载中...</h1>
        <p id="hero-subtitle" class="hero-subtitle">正在读取页面配置与接口能力。</p>
        <div class="hero-actions">
          <a class="button button-primary" href="#lead-form">提交线索</a>
          <a class="button button-secondary" href="/docs" target="_blank" rel="noreferrer">查看 Swagger</a>
        </div>
      </section>

      <section class="panel">
        <div class="panel-header">
          <h2>客户端能力</h2>
          <p>这个页面会直接请求后端接口，用来演示 Web、H5、小程序、App 共用 API 的典型形态。</p>
        </div>
        <div id="features" class="card-grid"></div>
      </section>

      <section class="panel">
        <div class="panel-header">
          <h2>可联调接口</h2>
          <p>下面这些就是当前演示页真正调用的 API。你可以直接在 Swagger 或客户端代码里复用它们。</p>
        </div>
        <div id="endpoints" class="endpoint-list"></div>
      </section>

      <section class="panel two-column">
        <div>
          <div class="panel-header">
            <h2>客户线索表单</h2>
            <p>模拟官网、H5 活动页、小程序落地页的留资动作。</p>
          </div>
          <form id="lead-form" class="form-grid">
            <label>
              姓名
              <input name="name" placeholder="例如：Liu Jun" required />
            </label>
            <label>
              邮箱
              <input name="email" type="email" placeholder="founder@example.com" required />
            </label>
            <label>
              公司
              <input name="company" placeholder="例如：Startup Studio" />
            </label>
            <label>
              客户端类型
              <select name="platform" required>
                <option value="WEB">Web</option>
                <option value="H5">H5</option>
                <option value="MINI_PROGRAM">小程序</option>
                <option value="APP">App</option>
              </select>
            </label>
            <label class="full-width">
              需求描述
              <textarea name="message" rows="4" placeholder="简单说说你想验证的业务流程"></textarea>
            </label>
            <button type="submit" class="button button-primary">提交线索</button>
          </form>
        </div>

        <div>
          <div class="panel-header">
            <h2>管理员演示台</h2>
            <p>登录默认管理员后，可以读取当前用户和线索列表，验证受保护接口与发布后的联调效果。</p>
          </div>
          <form id="login-form" class="form-grid">
            <label>
              管理员手机号
              <input name="phone" type="tel" value="13965026764" required />
            </label>
            <label>
              管理员密码
              <input name="password" type="password" value="123456" required />
            </label>
            <button type="submit" class="button button-secondary">登录并保存 Token</button>
          </form>
          <div class="action-row">
            <button id="health-button" class="button button-ghost" type="button">检查健康状态</button>
            <button id="me-button" class="button button-ghost" type="button">读取当前用户</button>
            <button id="leads-button" class="button button-ghost" type="button">读取线索列表</button>
            <button id="refresh-button" class="button button-ghost" type="button">刷新 Token</button>
            <button id="logout-button" class="button button-ghost" type="button">登出</button>
          </div>
        </div>
      </section>

      <section class="panel">
        <div class="panel-header">
          <h2>实时响应</h2>
          <p>这里会展示接口的返回结果，方便你确认本地开发、测试环境和发布后的行为是否一致。</p>
        </div>
        <pre id="response-output" class="response-box">等待操作...</pre>
      </section>
    </main>

    <script>
      window.__DEMO_API_BASE__ = '${apiBase}';
    </script>
    <script type="module" src="/demo/app.js"></script>
  </body>
</html>`;
}

export function getDemoPageStyles() {
  return `:root {
  --bg: #f5efe3;
  --paper: #fffaf2;
  --ink: #1f2a2e;
  --muted: #627177;
  --line: rgba(31, 42, 46, 0.14);
  --accent: #0f766e;
  --accent-soft: #d8f3ef;
  --sun: #e5983b;
  --shadow: 0 20px 50px rgba(31, 42, 46, 0.1);
}

* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: "Avenir Next", "PingFang SC", "Helvetica Neue", sans-serif;
  color: var(--ink);
  background:
    radial-gradient(circle at top left, rgba(229, 152, 59, 0.18), transparent 32%),
    radial-gradient(circle at bottom right, rgba(15, 118, 110, 0.18), transparent 28%),
    var(--bg);
}

.page {
  width: min(1120px, calc(100vw - 32px));
  margin: 0 auto;
  padding: 32px 0 72px;
}

.hero,
.panel {
  background: var(--paper);
  border: 1px solid var(--line);
  border-radius: 28px;
  box-shadow: var(--shadow);
}

.hero {
  padding: 40px;
  margin-bottom: 24px;
}

.eyebrow {
  margin: 0 0 12px;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: var(--accent);
  font-size: 12px;
  font-weight: 700;
}

h1,
h2 {
  margin: 0;
  font-family: Georgia, "Songti SC", serif;
}

h1 {
  font-size: clamp(32px, 6vw, 54px);
  line-height: 1;
  max-width: 10ch;
}

.hero-subtitle,
.panel-header p,
label,
input,
textarea,
select,
button {
  font-size: 16px;
}

.hero-subtitle,
.panel-header p {
  color: var(--muted);
  line-height: 1.7;
  max-width: 70ch;
}

.hero-actions,
.action-row {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 24px;
}

.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  border-radius: 999px;
  min-height: 44px;
  padding: 0 18px;
  text-decoration: none;
  font-weight: 700;
  cursor: pointer;
  transition: transform 160ms ease, box-shadow 160ms ease, background 160ms ease;
}

.button:hover {
  transform: translateY(-1px);
}

.button-primary {
  background: var(--ink);
  color: #fffaf2;
}

.button-secondary {
  background: var(--accent);
  color: white;
}

.button-ghost {
  border-color: var(--line);
  background: transparent;
  color: var(--ink);
}

.panel {
  padding: 28px;
  margin-bottom: 24px;
}

.panel-header {
  margin-bottom: 20px;
}

.card-grid,
.endpoint-list {
  display: grid;
  gap: 16px;
}

.card-grid {
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}

.card,
.endpoint-card {
  padding: 18px;
  border-radius: 20px;
  border: 1px solid var(--line);
  background: white;
}

.card h3,
.endpoint-card h3 {
  margin: 0 0 8px;
  font-size: 18px;
}

.card p,
.endpoint-card p {
  margin: 0;
  color: var(--muted);
  line-height: 1.65;
}

.badge {
  display: inline-flex;
  border-radius: 999px;
  padding: 6px 10px;
  background: var(--accent-soft);
  color: var(--accent);
  font-size: 12px;
  font-weight: 700;
  margin-bottom: 10px;
}

.endpoint-meta {
  margin-top: 12px;
  font-family: "SFMono-Regular", Consolas, monospace;
  font-size: 13px;
  color: var(--sun);
  word-break: break-all;
}

.two-column {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 24px;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.full-width {
  grid-column: 1 / -1;
}

label {
  display: grid;
  gap: 8px;
  color: var(--ink);
  font-weight: 600;
}

input,
textarea,
select {
  width: 100%;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: white;
  padding: 12px 14px;
  color: var(--ink);
}

.response-box {
  margin: 0;
  min-height: 240px;
  padding: 18px;
  border-radius: 20px;
  background: #142126;
  color: #e6f7f3;
  overflow: auto;
  font-size: 14px;
  line-height: 1.65;
}

@media (max-width: 820px) {
  .page { width: min(100vw - 20px, 100%); }
  .hero, .panel { padding: 20px; border-radius: 22px; }
  .two-column,
  .form-grid { grid-template-columns: 1fr; }
}`;
}

export function getDemoPageScript() {
  return `const apiBase = window.__DEMO_API_BASE__ || '/api/v1';

const output = document.getElementById('response-output');
const heroTitle = document.getElementById('hero-title');
const heroSubtitle = document.getElementById('hero-subtitle');
const features = document.getElementById('features');
const endpoints = document.getElementById('endpoints');

const leadForm = document.getElementById('lead-form');
const loginForm = document.getElementById('login-form');
const healthButton = document.getElementById('health-button');
const meButton = document.getElementById('me-button');
const leadsButton = document.getElementById('leads-button');
const refreshButton = document.getElementById('refresh-button');
const logoutButton = document.getElementById('logout-button');

const tokenStore = {
  get accessToken() {
    return localStorage.getItem('demo_access_token');
  },
  set accessToken(value) {
    if (value) {
      localStorage.setItem('demo_access_token', value);
    } else {
      localStorage.removeItem('demo_access_token');
    }
  },
  get refreshToken() {
    return localStorage.getItem('demo_refresh_token');
  },
  set refreshToken(value) {
    if (value) {
      localStorage.setItem('demo_refresh_token', value);
    } else {
      localStorage.removeItem('demo_refresh_token');
    }
  },
};

const renderJson = (title, value) => {
  output.textContent = title + '\\n\\n' + JSON.stringify(value, null, 2);
};

const jsonFetch = async (path, options = {}) => {
  const headers = new Headers(options.headers || {});
  headers.set('Content-Type', 'application/json');

  if (tokenStore.accessToken) {
    headers.set('Authorization', 'Bearer ' + tokenStore.accessToken);
  }

  const response = await fetch(path, {
    ...options,
    headers,
  });

  const body = await response.json();

  if (!response.ok) {
    throw body;
  }

  return body;
};

const loadPageData = async () => {
  const [configResponse, featuresResponse, endpointsResponse] = await Promise.all([
    jsonFetch(apiBase + '/site/config'),
    jsonFetch(apiBase + '/site/features'),
    jsonFetch(apiBase + '/site/client-endpoints'),
  ]);

  heroTitle.textContent = configResponse.data.title;
  heroSubtitle.textContent = configResponse.data.subtitle;

  features.innerHTML = featuresResponse.data
    .map(
      (item) => '<article class="card">' +
        '<span class="badge">' + item.tag + '</span>' +
        '<h3>' + item.title + '</h3>' +
        '<p>' + item.description + '</p>' +
      '</article>',
    )
    .join('');

  endpoints.innerHTML = endpointsResponse.data
    .map(
      (item) => '<article class="endpoint-card">' +
        '<span class="badge">' + item.audience + '</span>' +
        '<h3>' + item.name + '</h3>' +
        '<p>' + item.description + '</p>' +
        '<div class="endpoint-meta">' + item.method + ' ' + item.path + '</div>' +
      '</article>',
    )
    .join('');

  renderJson('页面初始化完成', {
    config: configResponse,
    features: featuresResponse,
    endpoints: endpointsResponse,
  });
};

leadForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const formData = new FormData(leadForm);
  const payload = Object.fromEntries(formData.entries());

  try {
    const response = await jsonFetch(apiBase + '/site/leads', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    renderJson('线索提交成功', response);
    leadForm.reset();
  } catch (error) {
    renderJson('线索提交失败', error);
  }
});

loginForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const formData = new FormData(loginForm);
  const payload = Object.fromEntries(formData.entries());

  try {
    const response = await jsonFetch(apiBase + '/auth/login', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    tokenStore.accessToken = response.data.tokens.accessToken;
    tokenStore.refreshToken = response.data.tokens.refreshToken;
    renderJson('登录成功，Token 已保存到本地浏览器存储', response);
  } catch (error) {
    renderJson('登录失败', error);
  }
});

healthButton.addEventListener('click', async () => {
  try {
    const response = await jsonFetch('/health', { method: 'GET', headers: {} });
    renderJson('健康检查结果', response);
  } catch (error) {
    renderJson('健康检查失败', error);
  }
});

meButton.addEventListener('click', async () => {
  try {
    const response = await jsonFetch(apiBase + '/users/me', { method: 'GET' });
    renderJson('当前用户', response);
  } catch (error) {
    renderJson('读取当前用户失败', error);
  }
});

leadsButton.addEventListener('click', async () => {
  try {
    const response = await jsonFetch(apiBase + '/site/leads?page=1&pageSize=10', {
      method: 'GET',
    });
    renderJson('线索列表', response);
  } catch (error) {
    renderJson('读取线索列表失败', error);
  }
});

refreshButton.addEventListener('click', async () => {
  try {
    const response = await jsonFetch(apiBase + '/auth/refresh', {
      method: 'POST',
      body: JSON.stringify({ refreshToken: tokenStore.refreshToken }),
    });
    tokenStore.accessToken = response.data.tokens.accessToken;
    tokenStore.refreshToken = response.data.tokens.refreshToken;
    renderJson('刷新 Token 成功', response);
  } catch (error) {
    renderJson('刷新 Token 失败', error);
  }
});

logoutButton.addEventListener('click', async () => {
  try {
    const response = await jsonFetch(apiBase + '/auth/logout', {
      method: 'POST',
      body: JSON.stringify({ refreshToken: tokenStore.refreshToken }),
    });
    tokenStore.accessToken = '';
    tokenStore.refreshToken = '';
    renderJson('登出成功', response);
  } catch (error) {
    tokenStore.accessToken = '';
    tokenStore.refreshToken = '';
    renderJson('已清空本地 Token', error);
  }
});

void loadPageData();`;
}
