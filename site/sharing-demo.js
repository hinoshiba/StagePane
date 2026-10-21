(() => {
  const demo = document.querySelector('.sharing-demo');
  if (!demo) return;

  const copy = {
    ja: {
      hint: 'Stageのウインドウをドラッグして配置を変えられます。手元のMacの配置は変わりません。',
      keyboard: '矢印キーで移動、Shiftと矢印キーで大きく移動、Homeで元の位置に戻せます。',
      shared: '相手に見える画面', move: '配置を動かす',
      chatChannel: '# チーム',
      chatLine1: '新しい案を共有しました',
      chatLine2: 'あとで確認します！',
      chatLine3: 'ランチ、何にする？'
    },
    en: {
      hint: 'Drag the windows on the Stage to arrange them. The layout on your Mac stays in place.',
      keyboard: 'Use arrow keys to move, Shift + arrow keys for larger steps, and Home to restore the starting position.',
      shared: 'What your audience sees', move: 'Move this window',
      chatChannel: '# team',
      chatLine1: 'A new idea is ready',
      chatLine2: 'I’ll take a look soon!',
      chatLine3: 'What’s for lunch?'
    }
  };
  // Synthetic examples only. Notifications are created inside the local desktop.
  const messages = [
    { app: 'Slack', icon: '#', color: '#54344d', ja: 'デザインチーム：新しい案を共有しました', en: 'Design team: a new idea is ready' },
    { app: 'Slack', icon: '#', color: '#54344d', ja: 'チーム雑談：ランチ、何にする？', en: 'Team chat: what’s for lunch?' },
    { app: 'Mail', icon: '✉', color: '#2678b5', ja: 'メール：週末のイベントのお知らせ', en: 'Mail: your weekend events roundup' },
    { app: 'Calendar', icon: '24', color: '#bd514e', ja: 'カレンダー：次の打ち合わせまで10分', en: 'Calendar: your next meeting is in 10 minutes' },
    { app: 'Messages', icon: '…', color: '#38865f', ja: 'メッセージ：帰りに買い物をお願い！', en: 'Messages: could you pick up groceries?' },
    { app: 'Slack', icon: '#', color: '#54344d', ja: 'プロジェクト：レビューありがとうございます！', en: 'Project chat: thanks for the review!' }
  ];
  const surface = demo.querySelector('.shared-windows');
  const notifications = demo.querySelector('.notification-stack');
  const notificationTemplate = notifications.querySelector('.notification');
  notificationTemplate.querySelector('p').removeAttribute('data-i18n');
  notificationTemplate.dataset.messageIndex = '0';
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  let inView = false;
  let notificationTimer;
  let messageIndex = 0;
  let messageQueue = [];
  let drag = null;
  let hasArranged = false;
  const text = () => copy[document.documentElement.lang === 'en' ? 'en' : 'ja'];
  const clamp = value => Math.min(1, Math.max(0, value));

  demo.classList.add('is-interactive');
  demo.querySelector('.demo-views').removeAttribute('aria-hidden');
  demo.querySelectorAll('.local-desktop, .stage-bridge, .stage-topline, .stage-wordmark').forEach(element => {
    element.setAttribute('aria-hidden', 'true');
  });
  surface.setAttribute('role', 'group');
  const windows = [...surface.querySelectorAll('.visual-window')].map((element, index) => {
    [...element.children].forEach(child => child.setAttribute('aria-hidden', 'true'));
    const handle = document.createElement('button');
    handle.type = 'button';
    handle.className = 'window-drag-handle';
    handle.setAttribute('aria-describedby', 'demo-drag-hint demo-keyboard-hint');
    element.append(handle);
    element.style.zIndex = String(index + 1);
    return { element, handle, x: index, y: .5, home: { x: index, y: .5 } };
  });

  function bounds(item) {
    return {
      x: Math.max(0, surface.clientWidth - item.element.offsetWidth),
      y: Math.max(0, surface.clientHeight - item.element.offsetHeight)
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
      const fittingWidth = Math.max(1, (surface.clientHeight * .82 - chromeHeight - 2) / .82);
      item.element.style.width = `${Math.min(surface.clientWidth * .48, fittingWidth)}px`;
    });
    const gap = Math.min(12, surface.clientWidth * .04);
    let left = Math.max(0, (surface.clientWidth - windows.reduce((width, item) => width + item.element.offsetWidth, 0) - gap) / 2);
    windows.forEach(item => {
      const limit = bounds(item);
      item.home = { x: limit.x ? clamp(left / limit.x) : 0, y: .5 };
      if (!hasArranged) Object.assign(item, item.home);
      place(item);
      left += item.element.offsetWidth + gap;
    });
  }

  function select(item) {
    windows.forEach(other => {
      other.element.style.zIndex = other === item ? '2' : '1';
    });
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
      hasArranged = true;
      place(item);
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
      hasArranged = true;
      place(item);
      const position = `${Math.round(item.x * 100)}%, ${Math.round(item.y * 100)}%`;
      demo.querySelector('.demo-announcement').textContent = `${item.handle.getAttribute('aria-label')}: ${position}`;
    });
  });

  function renderNotification(card) {
    const message = messages[Number(card.dataset.messageIndex)];
    card.querySelector('strong').textContent = message.app;
    const icon = card.querySelector('.notification-icon');
    icon.textContent = message.icon;
    icon.style.backgroundColor = message.color;
    card.querySelector('p').textContent = message[document.documentElement.lang === 'en' ? 'en' : 'ja'];
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
    const card = notificationTemplate.cloneNode(true);
    card.dataset.messageIndex = String(messageIndex);
    card.classList.add('is-entering');
    card.addEventListener('animationend', () => card.classList.remove('is-entering'), { once: true });
    renderNotification(card);
    notifications.prepend(card);
    while (notifications.children.length > 2) notifications.lastElementChild.remove();
  }

  function scheduleNotification() {
    clearTimeout(notificationTimer);
    if (reducedMotion.matches || !inView || document.hidden) return;
    notificationTimer = setTimeout(() => {
      nextMessage();
      scheduleNotification();
    }, 1900 + Math.random() * 1300);
  }

  function updateLanguage() {
    demo.querySelectorAll('[data-demo-text]').forEach(element => {
      element.textContent = text()[element.dataset.demoText];
    });
    surface.setAttribute('aria-label', text().shared);
    windows.forEach(item => {
      const title = item.element.querySelector('.window-chrome > span:last-child').textContent;
      item.handle.setAttribute('aria-label', `${text().shared} · ${title} — ${text().move}`);
    });
    demo.querySelector('.demo-announcement').textContent = '';
    [...notifications.children].forEach(renderNotification);
  }

  document.addEventListener('stagepane:languagechange', () => { endDrag(); updateLanguage(); fitWindows(); });
  document.addEventListener('visibilitychange', () => { endDrag(); scheduleNotification(); });
  window.addEventListener('blur', () => endDrag());
  reducedMotion.addEventListener('change', () => {
    if (reducedMotion.matches) {
      while (notifications.children.length > 1) notifications.lastElementChild.remove();
    }
    scheduleNotification();
  });
  new ResizeObserver(() => { endDrag(); fitWindows(); }).observe(surface);
  new IntersectionObserver(entries => {
    inView = entries[0].isIntersecting && entries[0].intersectionRatio >= .15;
    scheduleNotification();
  }, { threshold: .15 }).observe(demo.querySelector('.local-desktop'));
  fitWindows();
  updateLanguage();
})();
