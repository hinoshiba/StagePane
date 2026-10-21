(() => {
  const demo = document.querySelector('.sharing-demo');
  if (!demo) return;

  const copy = {
    ja: {
      hint: '両側の画面をドラッグ。配置はそれぞれ独立しています。',
      keyboard: '矢印キーで移動、Shiftと矢印キーで大きく移動、Homeで元の位置に戻せます。',
      pause: '通知を一時停止', resume: '通知を再開', reset: '配置をリセット',
      local: 'あなたのMac', shared: '相手に見える画面', move: '配置を動かす',
      resetDone: '両側の配置を元に戻しました。',
      moved: '配置を変更しました。もう片側の配置は変わりません。',
      illustration: '操作デモ'
    },
    en: {
      hint: 'Drag the windows on either side. Each layout is independent.',
      keyboard: 'Use arrow keys to move, Shift + arrow keys for larger steps, and Home to restore the starting position.',
      pause: 'Pause notifications', resume: 'Resume notifications', reset: 'Reset layouts',
      local: 'Your Mac', shared: 'What your audience sees', move: 'Move this window',
      resetDone: 'Both layouts have been reset.',
      moved: 'Layout changed. The other view stays in place.',
      illustration: 'Demo'
    }
  };
  // Synthetic examples only. Notifications never enter the shared surface.
  const messages = [
    { app: 'Slack', icon: '#', color: '#54344d', ja: 'デザインチーム：新しい案を共有しました', en: 'Design team: a new idea is ready' },
    { app: 'Slack', icon: '#', color: '#54344d', ja: 'チーム雑談：ランチ、何にする？', en: 'Team chat: what’s for lunch?' },
    { app: 'Mail', icon: '✉', color: '#2678b5', ja: 'メール：週末のイベントのお知らせ', en: 'Mail: your weekend events roundup' },
    { app: 'Calendar', icon: '24', color: '#bd514e', ja: 'カレンダー：次の打ち合わせまで10分', en: 'Calendar: your next meeting is in 10 minutes' },
    { app: 'Messages', icon: '…', color: '#38865f', ja: 'メッセージ：帰りに買い物をお願い！', en: 'Messages: could you pick up groceries?' },
    { app: 'Slack', icon: '#', color: '#54344d', ja: 'プロジェクト：レビューありがとうございます！', en: 'Project chat: thanks for the review!' }
  ];
  const toolbar = demo.querySelector('.demo-toolbar');
  const toggle = demo.querySelector('.demo-notifications-toggle');
  const notification = demo.querySelector('.notification');
  const notificationText = notification.querySelector('p');
  notificationText.removeAttribute('data-i18n');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  let paused = reducedMotion.matches;
  let inView = false;
  let notificationVisible = true;
  let notificationTimer;
  let messageIndex = 0;
  let messageQueue = [];
  let drag = null;
  let stageLayout = 'side-by-side';
  const text = () => copy[document.documentElement.lang === 'en' ? 'en' : 'ja'];
  const clamp = value => Math.min(1, Math.max(0, value));
  const surfaces = [demo.querySelector('.local-windows'), demo.querySelector('.shared-windows')];

  demo.classList.add('is-interactive');
  demo.querySelector('.demo-views').removeAttribute('aria-hidden');
  demo.querySelectorAll('.desktop-menubar, .personal-note, .desktop-dock, .stage-bridge, .stage-topline, .stage-wordmark').forEach(element => {
    element.setAttribute('aria-hidden', 'true');
  });
  const windows = surfaces.flatMap((surface, surfaceIndex) => {
    surface.setAttribute('role', 'group');
    return [...surface.querySelectorAll('.visual-window')].map((element, index) => {
      [...element.children].forEach(child => child.setAttribute('aria-hidden', 'true'));
      const handle = document.createElement('button');
      handle.type = 'button';
      handle.className = 'window-drag-handle';
      handle.setAttribute('aria-describedby', 'demo-drag-hint demo-keyboard-hint');
      element.append(handle);
      return { element, handle, surface, surfaceIndex, index, x: index, y: .5, width: .48 };
    });
  });

  function bounds(item) {
    return {
      x: Math.max(0, item.surface.clientWidth - item.element.offsetWidth),
      y: Math.max(0, item.surface.clientHeight - item.element.offsetHeight)
    };
  }

  function place(item) {
    const limit = bounds(item);
    item.element.style.left = `${item.x * limit.x}px`;
    item.element.style.top = `${item.y * limit.y}px`;
  }

  function fitWindows() {
    windows.forEach(item => {
      const chromeHeight = item.element.querySelector('.window-chrome').offsetHeight;
      const fittingWidth = Math.max(1, (item.surface.clientHeight * .82 - chromeHeight - 2) / .82);
      item.element.style.width = `${Math.min(item.surface.clientWidth * item.width, fittingWidth)}px`;
      place(item);
    });
    if (stageLayout === 'side-by-side') {
      const shared = windows.filter(item => item.surfaceIndex === 1);
      const surfaceWidth = surfaces[1].clientWidth;
      const gap = Math.min(12, surfaceWidth * .04);
      let left = Math.max(0, (surfaceWidth - shared[0].element.offsetWidth - shared[1].element.offsetWidth - gap) / 2);
      shared.forEach(item => {
        const limit = bounds(item);
        item.x = limit.x ? clamp(left / limit.x) : 0;
        item.home.x = item.x;
        place(item);
        left += item.element.offsetWidth + gap;
      });
    }
  }

  function select(item) {
    windows.filter(other => other.surface === item.surface).forEach(other => {
      other.element.style.zIndex = other === item ? '2' : '1';
    });
  }

  function updatePreset(value) {
    stageLayout = value;
    toolbar.querySelectorAll('[data-layout]').forEach(button => {
      button.setAttribute('aria-pressed', String(button.dataset.layout === value));
    });
  }

  function arrange(layout, resetLocal = false) {
    endDrag();
    windows.forEach(item => {
      if (item.surfaceIndex === 0) {
        if (!resetLocal) return;
        item.x = item.index ? .88 : .08;
        item.y = item.index ? .9 : .04;
        item.width = .49;
      } else {
        const overlap = layout === 'overlap';
        item.x = overlap ? (item.index ? .65 : .25) : item.index;
        item.y = overlap ? (item.index ? .9 : .1) : .5;
        item.width = overlap ? .57 : .48;
      }
      item.home = { x: item.x, y: item.y };
      item.element.style.zIndex = String(item.index + 1);
    });
    updatePreset(layout);
    fitWindows();
  }

  function announce(key) {
    demo.querySelector('.demo-announcement').textContent = text()[key];
  }

  function endDrag(event) {
    if (!drag || (event && event.pointerId !== drag.pointerId)) return;
    const { item, pointerId } = drag;
    drag = null;
    item.element.classList.remove('is-dragging');
    if (item.handle.hasPointerCapture(pointerId)) item.handle.releasePointerCapture(pointerId);
  }

  windows.forEach(item => {
    item.handle.addEventListener('focus', () => select(item));
    item.handle.addEventListener('pointerdown', event => {
      if (!event.isPrimary || event.button !== 0 || drag) return;
      event.preventDefault();
      item.handle.focus({ preventScroll: true });
      select(item);
      const limit = bounds(item);
      drag = { item, pointerId: event.pointerId, startX: event.clientX, startY: event.clientY, x: item.x * limit.x, y: item.y * limit.y };
      item.handle.setPointerCapture(event.pointerId);
      item.element.classList.add('is-dragging');
    });
    item.handle.addEventListener('pointermove', event => {
      if (!drag || drag.item !== item || event.pointerId !== drag.pointerId) return;
      const limit = bounds(item);
      item.x = limit.x ? clamp((drag.x + event.clientX - drag.startX) / limit.x) : 0;
      item.y = limit.y ? clamp((drag.y + event.clientY - drag.startY) / limit.y) : 0;
      place(item);
      if (item.surfaceIndex === 1) updatePreset(null);
    });
    ['pointerup', 'pointercancel', 'lostpointercapture'].forEach(type => item.handle.addEventListener(type, endDrag));
    item.handle.addEventListener('keydown', event => {
      const directions = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] };
      if (!directions[event.key] && event.key !== 'Home') return;
      event.preventDefault();
      endDrag();
      select(item);
      if (event.key === 'Home') {
        Object.assign(item, item.home);
      } else {
        const limit = bounds(item);
        const [dx, dy] = directions[event.key];
        const step = event.shiftKey ? 30 : 10;
        item.x = limit.x ? clamp(item.x + dx * step / limit.x) : 0;
        item.y = limit.y ? clamp(item.y + dy * step / limit.y) : 0;
      }
      place(item);
      if (item.surfaceIndex === 1) updatePreset(null);
      const position = `${Math.round(item.x * 100)}%, ${Math.round(item.y * 100)}%`;
      demo.querySelector('.demo-announcement').textContent = `${item.handle.getAttribute('aria-label')}: ${position}`;
    });
  });

  function renderNotification() {
    const message = messages[messageIndex];
    notification.querySelector('strong').textContent = message.app;
    const icon = notification.querySelector('.notification-icon');
    icon.textContent = message.icon;
    icon.style.backgroundColor = message.color;
    notificationText.textContent = message[document.documentElement.lang === 'en' ? 'en' : 'ja'];
  }

  function nextMessage() {
    // Shuffle each round, with no immediate repeat at the round boundary.
    if (!messageQueue.length) {
      messageQueue = messages.map((_, index) => index);
      for (let i = messageQueue.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [messageQueue[i], messageQueue[j]] = [messageQueue[j], messageQueue[i]];
      }
      if (messageQueue[0] === messageIndex) [messageQueue[0], messageQueue[1]] = [messageQueue[1], messageQueue[0]];
    }
    messageIndex = messageQueue.shift();
    renderNotification();
  }

  function scheduleNotification() {
    clearTimeout(notificationTimer);
    if (paused || !inView || document.hidden) return;
    notificationTimer = setTimeout(() => {
      notificationVisible = !notificationVisible;
      if (notificationVisible) nextMessage();
      notification.classList.toggle('is-hidden', !notificationVisible);
      scheduleNotification();
    }, notificationVisible ? 3800 : 1600 + Math.random() * 2400);
  }

  function updateLanguage() {
    demo.querySelectorAll('[data-demo-text]').forEach(element => {
      element.textContent = text()[element.dataset.demoText];
    });
    toggle.setAttribute('aria-label', text()[paused ? 'resume' : 'pause']);
    toggle.title = text()[paused ? 'resume' : 'pause'];
    toggle.classList.toggle('is-paused', paused);
    const reset = demo.querySelector('.demo-reset');
    reset.setAttribute('aria-label', text().reset);
    reset.title = text().reset;
    surfaces.forEach((surface, index) => surface.setAttribute('aria-label', text()[index ? 'shared' : 'local']));
    windows.forEach(item => {
      const title = item.element.querySelector('.window-chrome > span:last-child').textContent;
      item.handle.setAttribute('aria-label', `${text()[item.surfaceIndex ? 'shared' : 'local']} · ${title} — ${text().move}`);
    });
    demo.querySelector('.demo-announcement').textContent = '';
    renderNotification();
  }

  toolbar.addEventListener('click', event => {
    const preset = event.target.closest('[data-layout]');
    if (preset) { arrange(preset.dataset.layout); announce('moved'); }
    if (event.target.closest('.demo-reset')) { arrange('side-by-side', true); announce('resetDone'); }
    if (event.target.closest('.demo-notifications-toggle')) {
      paused = !paused;
      updateLanguage();
      scheduleNotification();
    }
  });
  document.addEventListener('stagepane:languagechange', () => { endDrag(); updateLanguage(); fitWindows(); });
  document.addEventListener('visibilitychange', () => { endDrag(); scheduleNotification(); });
  window.addEventListener('blur', () => endDrag());
  reducedMotion.addEventListener('change', () => {
    if (reducedMotion.matches) paused = true;
    updateLanguage();
    scheduleNotification();
  });
  new ResizeObserver(() => { endDrag(); fitWindows(); }).observe(demo.querySelector('.demo-views'));
  new IntersectionObserver(entries => {
    inView = entries[0].isIntersecting && entries[0].intersectionRatio >= .15;
    scheduleNotification();
  }, { threshold: .15 }).observe(demo.querySelector('.local-desktop'));
  arrange('side-by-side', true);
  updateLanguage();
  toolbar.hidden = false;
})();
