const translations = {
  "t98": {
    "html": {
      "ja": "選択した画面と手書きは、Mac上でStageを表示するために処理します。画面の配信は、利用者が選んだ会議アプリが行います。",
      "en": "Selected screen content and drawings are processed on your Mac to display the Stage. Your chosen meeting app handles screen-sharing transmission."
    }
  },
  "t99": {
    "html": {
      "ja": "設定はMacに保存します。保存するのはStageの形状と外観、ウインドウの動作、セーフエリアガイドとStagePaneマークの設定、ポインタのスタイル・大きさ・色・グロー、カーテンの文言と文字の大きさ、手書きツールの設定、レイヤー一覧の幅、最後に選択した設定項目、Macの画面収録アクセスの初回確認が済んだかどうか、およびWorkspace・Stage・このアプリについて・Pro・Macの画面収録アクセスの各ウインドウの位置と大きさです。許可状態そのものは保存せず、macOSから確認します。Mac App Store版はこれに加えて、App Storeの評価依頼を表示する時期の判断にだけ使うローカルな3つの値（成功したセッションの回数、その最初の日付、評価依頼を最後に表示したアプリのバージョン）を保存します。画面、ソース名、Stage上のソースの配置、手書きは保存しません。手書きは作業中のメモリで扱い、「すべて停止」または終了で破棄します。「画像をコピー」はシステムのクリップボードへPNGを置き、ほかのアプリから参照できます。「PNGを保存」は選択した場所へ書き込みます。不要な画像は利用者が削除できます。",
      "en": "Preferences are stored on your Mac: the Stage shape and appearance, window behavior, the safe-area guide and StagePane mark settings, the pointer style, size, color, and glow, the Curtain message and its text size, drawing tool settings, the layer list width, the last selected Settings pane, whether the first Mac Screen Recording Access check has been completed, and the position and size of the Workspace, Stage, About, Pro, and Mac Screen Recording Access windows. The access status itself is read from macOS, not saved by StagePane. The Mac App Store build additionally stores three local values used only to decide when to show the App Store rating prompt: a count of successful sessions, the date of the first one, and the app version in which the prompt was last shown. Screen content, source names, the Stage layout of your sources, and drawings are not stored. Drawings are held in memory during use and are discarded when you choose Stop All or quit. Copy Image places a PNG on the system clipboard, where other apps may access it; Save PNG writes to your chosen location. You can delete saved images when no longer needed."
    }
  },
  "t100": {
    "html": {
      "ja": "開発者はアプリ内の画面や個人データを収集しません。Proの購入・復元はAppleが処理します。このサイトはGitHub Pagesで配信され、接続情報は配信事業者に処理されます。",
      "en": "The developer does not collect screen content or personal data from the app. Apple processes Pro purchases and restores. GitHub Pages hosts this website and processes connection information."
    }
  },
  "t101": {
    "html": {
      "ja": "画面の選択はAppleの共有ピッカーで変更できます。切り抜きは表示範囲を変える機能で、選択したソース全体の取得範囲は変わりません。カーテンはStageの表示を覆い、取得を終了するには「すべて停止」を使います。アプリ全体のMacの画面収録アクセスは任意で、「許可する」を選んだ場合だけ要求します。macOSのシステム設定で変更でき、未許可でもピッカーで選んだ内容は共有できます。",
      "en": "Use Apple’s sharing picker to change the selected content. Cropping changes the displayed area, while the complete selected source is still captured. The Curtain covers the Stage; use Stop All to end capture. App-wide Mac Screen Recording Access is optional and requested only when you choose Allow. You can change it in macOS System Settings; picker-based sharing works without it."
    }
  },
  "privacy-sharing": {
    "html": {
      "ja": "StagePaneは、画面、手書き、その他のデータを開発者や第三者へ送信しません。このアプリはネットワークのエンタイトルメントを持たずに配布されており、アプリ自身がネットワーク接続を開くことはできません。画面はソースが動作している間だけメモリで保持し、そのソースを非表示または解除したとき、「すべて停止」を選んだとき、終了したときに解放します。画面に由来するデータで残るのは、利用者自身が「画像をコピー」「PNGを保存」で作成した画像だけで、クリップボードまたは選択した場所に残ります。Proの購入・復元はAppleが処理し、その処理に画面は一切含まれません。",
      "en": "StagePane does not transmit screen content, drawings, or any other data to the developer or to any third party. The app ships without a network entitlement and cannot open network connections of its own. Screen content is held only in memory while a source is live and is released when you hide or remove that source, choose Stop All, or quit. The only screen-derived data that persists is an image you create yourself with Copy Image or Save PNG, on your clipboard or at the location you chose. Apple processes Pro purchases and restores; no screen content is part of that flow."
    }
  },
  "privacy-static-en": {
    "html": {
      "ja": "英語版のプライバシーポリシーは、JavaScriptなしで読める<a class=\"contact-link\" href=\"en/privacy/\" hreflang=\"en\" lang=\"en\">静的ページ</a>でも公開しています。",
      "en": "The English policy is also published as a <a class=\"contact-link\" href=\"en/privacy/\" hreflang=\"en\" lang=\"en\">static page</a> that can be read without JavaScript."
    }
  },
  "contact-retention": {
    "html": {
      "ja": "問い合わせのメールアドレスと本文は対応のために必要な期間だけ保管し、削除依頼を受け付けます。",
      "en": "Support email addresses and messages are retained only as needed to handle your inquiry and can be deleted on request."
    }
  },
  "t103": {
    "html": {
      "ja": "公式アプリはMac App Storeで配信しています。価格、追加購入の内容、対応環境はApp Storeとアプリ内の購入画面をご確認ください。購入・支払い・返金の手続きにはAppleの規定が適用されます。このサイトでは販売・決済を行いません。",
      "en": "The official app is distributed through the Mac App Store. Check the App Store and in-app purchase screen for pricing, purchase details, and requirements. Apple’s terms apply to purchases, payment, and refund requests. This website does not sell products or process payments."
    }
  },
  "t104": {
    "html": {
      "ja": "Appleの購入サポート",
      "en": "Apple purchase support"
    }
  },
  "sales-disclosure": {
    "html": {
      "ja": "販売事業者の氏名、住所および電話番号については、「特定商取引法に基づく表記」の開示請求をいただいた場合、法令に基づき遅滞なく電子メールにて提供いたします。",
      "en": "Upon request for a disclosure under Japan’s Act on Specified Commercial Transactions, the seller’s name, address, and telephone number will be provided by email without delay in accordance with applicable law."
    }
  },
  "sales-disclosure-contact": {
    "html": {
      "ja": "購入判断前に確認できるよう、<a class=\"contact-link\" href=\"mailto:support@hinoshiba.com\">support@hinoshiba.com</a>へご請求ください。購入済みである必要はありません。",
      "en": "To review this information before deciding to purchase, contact <a class=\"contact-link\" href=\"mailto:support@hinoshiba.com\">support@hinoshiba.com</a>. A prior purchase is not required."
    }
  },
  "sales-reference": {
    "html": {
      "ja": "参考: 特定商取引法ガイド",
      "en": "Reference: Guide to the Act on Specified Commercial Transactions (Japanese)"
    }
  },
  "t122": {
    "html": {
      "ja": "<strong>ライセンス:</strong> ソースコードとロゴ・アイコンの著作物はApache License 2.0です。StagePaneの名称やロゴを、公式性や提携を示す商標として使う権利は付与されません。",
      "en": "<strong>License:</strong> The source code and the copyright in the logo and icon artwork are available under Apache License 2.0. The license does not grant the right to use the StagePane name or logo as a trademark suggesting official status or affiliation."
    }
  },
  "skip": {
    "html": {
      "ja": "本文へ移動",
      "en": "Skip to main content"
    }
  },
  "home": {
    "aria-label": {
      "ja": "StagePane ホーム",
      "en": "StagePane home"
    }
  },
  "nav": {
    "aria-label": {
      "ja": "メインナビゲーション",
      "en": "Primary navigation"
    }
  },
  "features": {
    "html": {
      "ja": "共有のしくみ",
      "en": "How sharing works"
    }
  },
  "how": {
    "html": {
      "ja": "使い方",
      "en": "Get started"
    }
  },
  "support": {
    "html": {
      "ja": "サポート",
      "en": "Support"
    }
  },
  "menu": {
    "html": {
      "ja": "メニュー",
      "en": "Menu"
    }
  },
  "language": {
    "html": {
      "ja": "EN",
      "en": "日本語"
    },
    "href": {
      "ja": "?lang=en",
      "en": "?lang=ja"
    },
    "data-language": {
      "ja": "en",
      "en": "ja"
    },
    "hreflang": {
      "ja": "en",
      "en": "ja"
    },
    "lang": {
      "ja": "en",
      "en": "ja"
    },
    "aria-label": {
      "ja": "英語に切り替える",
      "en": "Switch to Japanese"
    }
  },
  "store": {
    "html": {
      "ja": "Mac App Store",
      "en": "Mac App Store"
    },
    "href": {
      "ja": "https://apps.apple.com/jp/app/id6802005741",
      "en": "https://apps.apple.com/us/app/id6802005741"
    }
  },
  "store-cta": {
    "html": {
      "ja": "App Storeで無料入手",
      "en": "Get it free on the App Store"
    },
    "href": {
      "ja": "https://apps.apple.com/jp/app/id6802005741",
      "en": "https://apps.apple.com/us/app/id6802005741"
    }
  },
  "eyebrow": {
    "html": {
      "ja": "画面共有のためのmacOSアプリ",
      "en": "A calmer way to share your screen"
    }
  },
  "hero-title": {
    "html": {
      "ja": "見せたいものを、<br>ひとつの画面に。",
      "en": "Your work, together.<br>Your space, private."
    }
  },
  "hero-lead": {
    "html": {
      "ja": "資料とデモは、相手へ。<br>Slackの通知や個人メモは、手元に。",
      "en": "Slides and demos for your audience. <br>Slack notifications and notes for you."
    }
  },
  "compatibility": {
    "html": {
      "ja": "macOS 14以降 · Apple Silicon / Intel",
      "en": "macOS 14 or later · Apple Silicon / Intel"
    }
  },
  "explain-title": {
    "html": {
      "ja": "注目を集める",
      "en": "Guide their attention"
    }
  },
  "explain-copy": {
    "html": {
      "ja": "ポインタ、手書き、虫眼鏡。伝えたいところを、その場で示せます。",
      "en": "Point, draw, or magnify to bring the important details into focus."
    }
  },
  "curtain-title": {
    "html": {
      "ja": "準備する間は、ひと呼吸",
      "en": "A moment to prepare"
    }
  },
  "curtain-copy": {
    "html": {
      "ja": "カーテンでStageを覆って、次の内容へ。画面の取得は続きます。",
      "en": "Cover the Stage with the Curtain while you prepare. Capture continues behind it."
    }
  },
  "workflow-title": {
    "html": {
      "ja": "次の会議で、すぐに。",
      "en": "Ready for your next meeting."
    }
  },
  "step-1": {
    "html": {
      "ja": "選ぶ",
      "en": "Choose"
    }
  },
  "step-1-copy": {
    "html": {
      "ja": "「ソースを追加」から、見せたいウインドウを1つずつ選びます。",
      "en": "Use Add Source to select each window you want to show."
    }
  },
  "step-2": {
    "html": {
      "ja": "並べる",
      "en": "Arrange"
    }
  },
  "step-2-copy": {
    "html": {
      "ja": "Workspaceで、大きさ・位置・表示範囲を整えます。",
      "en": "Set the size, position, and crop of your sources in the Workspace."
    }
  },
  "step-3": {
    "html": {
      "ja": "Stageを共有",
      "en": "Share the Stage"
    }
  },
  "step-3-copy": {
    "html": {
      "ja": "会議アプリで「StagePane Stage」を選び、共有対象を確認してカーテンを開きます。",
      "en": "Choose “StagePane Stage” in your meeting app, check the share target, then open the Curtain."
    }
  },
  "plan-title": {
    "html": {
      "ja": "まずは、無料で。",
      "en": "Start with Free."
    }
  },
  "plan-note": {
    "html": {
      "ja": "Proの価格はApp Store・アプリ内でご確認ください。利用できるソース数はMacの性能とOSの制約に依存します。",
      "en": "See the App Store or the app for Pro pricing. Available source capacity depends on your Mac and macOS."
    }
  },
  "faq-title": {
    "html": {
      "ja": "使う前に、少しだけ。",
      "en": "A few things to know."
    }
  },
  "faq-share": {
    "html": {
      "ja": "会議では何を共有すればよいですか？",
      "en": "Which window should I share?"
    }
  },
  "faq-share-copy": {
    "html": {
      "ja": "会議アプリで「StagePane Stage」ウインドウを選んでください。Workspaceは手元の編集用です。アプリ全体や画面全体を共有するとWorkspaceも映る場合があるため、共有対象を確認してください。",
      "en": "Select the “StagePane Stage” window in your meeting app. Workspace is your private editor. Sharing the whole app or display can include Workspace, so check your selected target."
    }
  },
  "faq-curtain": {
    "html": {
      "ja": "カーテンや切り抜きで、画面の取得は止まりますか？",
      "en": "Do the Curtain or cropping stop capture?"
    }
  },
  "faq-curtain-copy": {
    "html": {
      "ja": "カーテンはStageを覆い、切り抜きは表示範囲を変えます。どちらも選択したソースの取得は続きます。取得を終了するときは「すべて停止」を使ってください。",
      "en": "The Curtain covers the Stage, and cropping changes the visible area. Both keep capturing the selected source. Use Stop All to end capture."
    }
  },
  "faq-access": {
    "html": {
      "ja": "画面収録アクセスは必須ですか？",
      "en": "Is Screen Recording Access required?"
    }
  },
  "faq-access-copy": {
    "html": {
      "ja": "アプリ全体の画面収録アクセスは任意です。初回の案内を閉じても、Appleの選択画面で選んだ内容を共有できます。macOSによるソース選択や共有の確認は、その都度表示されることがあります。",
      "en": "App-wide Screen Recording Access is optional. You can dismiss the initial guide and still share content selected in Apple’s picker. macOS may show source selection or sharing confirmation each time."
    }
  },
  "privacy-title": {
    "html": {
      "ja": "プライバシーとポリシー",
      "en": "Privacy & policies"
    }
  },
  "privacy-summary": {
    "html": {
      "ja": "画面の扱い、保存される設定、販売について。",
      "en": "Screen content, saved preferences, and purchasing information."
    }
  },
  "privacy-full": {
    "html": {
      "ja": "プライバシーポリシー全文を読む",
      "en": "Read the full privacy policy"
    }
  },
  "terms-title": {
    "html": {
      "ja": "販売ポリシー",
      "en": "Sales policy"
    }
  },
  "disclaimer-title": {
    "html": {
      "ja": "免責事項",
      "en": "Disclaimer"
    }
  },
  "disclaimer-1": {
    "html": {
      "ja": "本サイトならびに本サイトで紹介・公開しているアプリケーション、コンテンツ、成果物およびソースコード等は、制作者が個人(hinoshiba)として制作・提供しているものです。",
      "en": "This website and the applications, content, deliverables, and source code introduced or published here are created and provided by the creator in an individual capacity (hinoshiba)."
    }
  },
  "disclaimer-2": {
    "html": {
      "ja": "これらは制作者が所属する組織・団体とは関係なく、所属組織・団体の公式な見解、製品、サービスまたは活動を示すものではありません。",
      "en": "They are unrelated to organizations or groups with which the creator is affiliated and do not represent those organizations’ official views, products, services, or activities."
    }
  },
  "disclaimer-3": {
    "html": {
      "ja": "本サイトおよび本アプリケーション等に関するお問い合わせ、サポートその他の責任は制作者個人が負うものであり、所属組織・団体はこれらの提供・運営には関与しておりません。",
      "en": "The individual creator is responsible for inquiries, support, and other matters concerning this website and these applications. Affiliated organizations or groups are not involved in their provision or operation."
    }
  },
  "disclaimer-4": {
    "html": {
      "ja": "本サイトまたは本アプリケーション等の利用により生じた損害については、法令上認められる範囲において、制作者は責任を負わないものとします。",
      "en": "To the extent permitted by applicable law, the creator is not liable for damages arising from use of this website or these applications."
    }
  },
  "build-title": {
    "html": {
      "ja": "オープンソースとライセンス",
      "en": "Open source and licensing"
    }
  },
  "build-copy": {
    "html": {
      "ja": "StagePaneのソースコードはApache License 2.0で公開しています。ビルド方法はREADMEをご覧ください。",
      "en": "StagePane’s source code is available under Apache License 2.0. See the README for build instructions."
    }
  },
  "repository": {
    "html": {
      "ja": "GitHubリポジトリ",
      "en": "GitHub repository"
    }
  },
  "build-readme": {
    "html": {
      "ja": "ビルド方法（README）",
      "en": "Build instructions (README)"
    }
  },
  "footer-nav": {
    "aria-label": {
      "ja": "関連リンク",
      "en": "Related links"
    }
  },
  "privacy-link": {
    "html": {
      "ja": "プライバシー",
      "en": "Privacy"
    }
  },
  "more-products": {
    "html": {
      "ja": "ほかの作品",
      "en": "More products"
    }
  },
  "footer-language": {
    "html": {
      "ja": "English",
      "en": "日本語"
    },
    "href": {
      "ja": "?lang=en",
      "en": "?lang=ja"
    },
    "data-language": {
      "ja": "en",
      "en": "ja"
    },
    "hreflang": {
      "ja": "en",
      "en": "ja"
    },
    "lang": {
      "ja": "en",
      "en": "ja"
    },
    "aria-label": {
      "ja": "英語に切り替える",
      "en": "Switch to Japanese"
    }
  },
  "workspace-image": {
    "alt": {
      "ja": "2つのレイヤーを並べたWorkspace。左にレイヤー一覧、右に資料と予約アプリの合成画面",
      "en": "Workspace with two layers: a layer list on the left and slides beside a booking app demo on the canvas"
    },
    "src": {
      "ja": "assets/screenshots/ja/product-workspace-light.webp?v=20261021-stage-lp",
      "en": "assets/screenshots/en/product-workspace-light.webp?v=20261021-stage-lp"
    }
  },
  "workspace-dark": {
    "srcset": {
      "ja": "assets/screenshots/ja/product-workspace-dark.webp?v=20261021-stage-lp",
      "en": "assets/screenshots/en/product-workspace-dark.webp?v=20261021-stage-lp"
    }
  },
  "workspace-zoom": {
    "aria-label": {
      "ja": "画像を拡大: 2つのレイヤーを並べたWorkspace。左にレイヤー一覧、右に資料と予約アプリの合成画面",
      "en": "Enlarge image: Workspace with two layers: a layer list on the left and slides beside a booking app demo on the canvas"
    }
  },
  "meta-title": {
    "content": {
      "ja": "StagePane — 見せたいものを、ひとつの画面に。",
      "en": "StagePane — Your work, together. Your space, private."
    }
  },
  "meta-description": {
    "content": {
      "ja": "資料とデモは相手へ、Slackの通知やメモは手元に。ウインドウを個別に選んで並べ、会議ではStageだけを共有するmacOSアプリ。選択したウインドウ内の通知は映る場合があります。4ソースまで無料。",
      "en": "Keep unselected Slack windows and notes out of your presentation. Choose individual windows and share only the Stage in your meeting. Notifications within selected windows may appear. Free for four sources."
    }
  },
  "meta-locale": {
    "content": {
      "ja": "ja_JP",
      "en": "en_US"
    }
  },
  "meta-alternate-locale": {
    "content": {
      "ja": "en_US",
      "en": "ja_JP"
    }
  },
  "meta-url": {
    "content": {
      "ja": "https://stagepane.hinoshiba.com/",
      "en": "https://stagepane.hinoshiba.com/?lang=en"
    }
  },
  "meta-image": {
    "content": {
      "ja": "https://stagepane.hinoshiba.com/assets/screenshots/ja/product-stage.webp?v=20261021-stage-lp",
      "en": "https://stagepane.hinoshiba.com/assets/screenshots/en/product-stage.webp?v=20261021-stage-lp"
    }
  },
  "meta-image-alt": {
    "content": {
      "ja": "説明資料と予約アプリのデモを左右に並べたStageの表示例",
      "en": "Sample Stage with presentation slides and a booking app demo side by side"
    }
  },
  "canonical": {
    "href": {
      "ja": "https://stagepane.hinoshiba.com/",
      "en": "https://stagepane.hinoshiba.com/?lang=en"
    }
  },
  "layout-eyebrow": {
    "html": {
      "ja": "いつもの操作で、見せやすく",
      "en": "Familiar moves. A clearer picture."
    }
  },
  "layout-title": {
    "html": {
      "ja": "並べる。重ねる。<br>伝わる形に。",
      "en": "Move. Resize.<br>Make your point."
    }
  },
  "layout-copy": {
    "html": {
      "ja": "大きさも、位置も、ウインドウのように。手元の配置を変えずに、共有する映像だけを整えられます。",
      "en": "Move and resize your sources like windows. Shape the shared view while keeping your own desktop arrangement."
    }
  },
  "workspace-caption": {
    "html": {
      "ja": "手元で整えるWorkspace。会議で共有するのはStageだけ。画面はサンプルです。",
      "en": "Arrange in your Workspace; share only the Stage. Screens show sample content."
    }
  },
  "local-title": {
    "html": {
      "ja": "画面の処理は、このMacで。",
      "en": "Processed on your Mac."
    }
  },
  "local-copy": {
    "html": {
      "ja": "StagePaneは画面を開発者へ送信しません。アカウントも不要です。参加者への配信は、お使いの会議アプリが行います。",
      "en": "StagePane processes your screen on your Mac and sends none of it to the developer. No account needed. Your meeting app handles transmission to participants."
    }
  },
  "plan-common": {
    "html": {
      "ja": "配置・切り抜き・手書き・虫眼鏡・カーテン。<br>基本の道具は、すべて無料で使えます。",
      "en": "Arrange, crop, draw, magnify, and use the Curtain.<br>All the essentials are included for free."
    }
  },
  "faq-notifications": {
    "html": {
      "ja": "通知はすべて隠れますか？",
      "en": "Are all notifications hidden?"
    }
  },
  "faq-notifications-copy": {
    "html": {
      "ja": "通知を自動で削除する機能ではありません。ウインドウを個別に選び、会議では「StagePane Stage」だけを共有すると、選択外の別アプリの通知はStageに含まれません。画面全体・アプリ全体を選んだ場合や、選択したウインドウ内の通知・ダイアログは共有されることがあります。",
      "en": "StagePane does not automatically remove notifications. Select individual windows and share only StagePane Stage in your meeting to keep other apps’ notifications outside the composition. Whole-display or whole-app sources, and notifications or dialogs within selected windows, may still be shared."
    }
  },
  "support-direct": {
    "html": {
      "ja": "お問い合わせは <a class=\"contact-link\" href=\"mailto:support@hinoshiba.com\">support@hinoshiba.com</a> へ。購入・請求・返金は <a class=\"contact-link\" href=\"https://support.apple.com/billing\">Appleの購入サポート</a> をご利用ください。",
      "en": "Contact <a class=\"contact-link\" href=\"mailto:support@hinoshiba.com\">support@hinoshiba.com</a> for product support. For purchases, billing, or refunds, visit <a class=\"contact-link\" href=\"https://support.apple.com/billing\">Apple purchase support</a>."
    }
  },
  "hero-description": {
    "html": {
      "ja": "ウインドウを個別に選び、共有専用のStageに。<br>会議では、そのStageだけを共有します。",
      "en": "Choose individual windows for your Stage. <br>Then share only that Stage in your meeting."
    }
  },
  "demo-local": {
    "html": {
      "ja": "あなたのMac",
      "en": "Your Mac"
    }
  },
  "demo-audience": {
    "html": {
      "ja": "相手に見える画面",
      "en": "What your audience sees"
    }
  },
  "demo-slides": {
    "html": {
      "ja": "説明資料",
      "en": "Slides"
    }
  },
  "demo-app": {
    "html": {
      "ja": "アプリのデモ",
      "en": "App demo"
    }
  },
  "demo-notes": {
    "html": {
      "ja": "自分用のメモ",
      "en": "Personal notes"
    }
  },
  "demo-note-line": {
    "html": {
      "ja": "次は、デモの操作を紹介",
      "en": "Next: walk through the demo"
    }
  },
  "demo-notification": {
    "html": {
      "ja": "新しいメッセージが届きました",
      "en": "You have a new message"
    }
  },
  "demo-illustration": {
    "html": {
      "ja": "ウインドウを個別に選んだときのイメージ",
      "en": "Illustration: individual windows selected"
    }
  },
  "demo-condition": {
    "html": {
      "ja": "会議では「StagePane Stage」だけを共有します。選択したウインドウ内の通知・ダイアログは映る場合があります。",
      "en": "Share only “StagePane Stage” in your meeting. Notifications and dialogs inside selected windows may appear."
    }
  },
  "demo-boundary": {
    "html": {
      "ja": "選ばなかったものは、共有の外に。",
      "en": "What you don’t select stays outside the Stage."
    }
  },
  "local-link": {
    "html": {
      "ja": "画面の扱いを詳しく見る <span aria-hidden=\"true\">↗</span>",
      "en": "How your screen content is handled <span aria-hidden=\"true\">↗</span>"
    }
  },
  "plan-intro": {
    "html": {
      "ja": "4つの画面で、資料もデモも。",
      "en": "Four views. Room for your whole story."
    }
  },
  "plan-free-label": {
    "html": {
      "ja": "無料",
      "en": "Free"
    }
  },
  "plan-source-unit": {
    "html": {
      "ja": "同時に使える画面",
      "en": "views at once"
    }
  },
  "plan-pro-label": {
    "html": {
      "ja": "もっと使うなら、Pro",
      "en": "Need more? Go Pro."
    }
  },
  "plan-pro-description": {
    "html": {
      "ja": "ソース数の上限を解除。<br>StagePaneロゴも非表示に。",
      "en": "Remove the app’s source limit.<br>Choose whether to show the StagePane mark."
    }
  },
  "plan-one-time": {
    "html": {
      "ja": "買い切りのアプリ内課金",
      "en": "One-time in-app purchase"
    }
  },
  "faq-interact": {
    "html": {
      "ja": "Stageの中でアプリを操作できますか？",
      "en": "Can I interact with apps inside the Stage?"
    }
  },
  "faq-interact-copy": {
    "html": {
      "ja": "アプリ自体の操作は元のウインドウで行います。Workspaceでは、共有する映像の位置・大きさ・重なりを調整できます。",
      "en": "Use the original windows to interact with your apps. The Workspace lets you arrange, resize, and layer their shared views."
    }
  },
  "plans-nav": {
    "html": {
      "ja": "無料とPro",
      "en": "Free & Pro"
    }
  },
  "diagram-description": {
    "html": {
      "ja": "手元の説明資料とアプリのデモだけをStageに配置。選んでいないSlackの通知と個人メモは、手元の画面に残ります。",
      "en": "Only the selected slides and app demo appear on the Stage. An unselected Slack notification and personal notes remain on your own desktop."
    }
  },
  "sample-project": {
    "html": {
      "ja": "体験予約の改善",
      "en": "Better bookings"
    }
  },
  "sample-title": {
    "html": {
      "ja": "体験予約を、<br>3ステップで。",
      "en": "Book a workshop.<br>In three steps."
    }
  },
  "sample-step1": {
    "html": {
      "ja": "日程",
      "en": "Date"
    }
  },
  "sample-step2": {
    "html": {
      "ja": "人数",
      "en": "Guests"
    }
  },
  "sample-step3": {
    "html": {
      "ja": "確認",
      "en": "Confirm"
    }
  },
  "sample-app-title": {
    "html": {
      "ja": "陶芸ワークショップ",
      "en": "Pottery workshop"
    }
  },
  "sample-app-date": {
    "html": {
      "ja": "10月24日（土）",
      "en": "Sat, Oct 24"
    }
  },
  "sample-app-action": {
    "html": {
      "ja": "予約内容を確認",
      "en": "Review booking"
    }
  },
  "demo-arrange": {
    "html": {
      "ja": "並べる",
      "en": "Side by side"
    }
  },
  "demo-overlap": {
    "html": {
      "ja": "重ねる",
      "en": "Overlap"
    }
  },
  "image-zoom": {
    "html": {
      "ja": "拡大 ↗",
      "en": "Enlarge ↗"
    }
  },
  "demo-controls": {
    "aria-label": {
      "ja": "Stageの配置例",
      "en": "Example Stage layouts"
    }
  }
};
const colorScheme = window.matchMedia('(prefers-color-scheme: dark)');
let currentLanguage = 'ja';

function updatePreviewLinks() {
  document.querySelectorAll('[data-preview]').forEach(link => {
    const kind = link.dataset.preview;
    const filename = kind + (colorScheme.matches ? '-dark' : '-light');
    link.href = 'assets/screenshots/' + currentLanguage + '/' + filename + '.webp?v=20261021-stage-lp';
  });
}

function updateLanguageLinks() {
  document.querySelectorAll('[data-language]').forEach(link => {
    link.href = '?lang=' + link.dataset.language + location.hash;
  });
}

function setLanguage(language, updateURL = false) {
  const lang = language === 'en' ? 'en' : 'ja';
  currentLanguage = lang;
  document.querySelectorAll('[data-i18n]').forEach(element => {
    const entry = translations[element.dataset.i18n];
    if (!entry) return;
    for (const [attribute, values] of Object.entries(entry)) {
      if (attribute === 'html') element.innerHTML = values[lang];
      else element.setAttribute(attribute, values[lang]);
    }
  });
  document.documentElement.lang = lang;
  document.title = translations['meta-title'].content[lang];
  updateLanguageLinks();
  const applicationData = document.getElementById('application-data');
  if (applicationData) {
    const data = JSON.parse(applicationData.textContent);
    data.description = translations['meta-description'].content[lang];
    data.url = translations['meta-url'].content[lang];
    applicationData.textContent = JSON.stringify(data);
  }
  updatePreviewLinks();
  if (updateURL) {
    const url = new URL(location.href);
    url.searchParams.set('lang', lang);
    history.pushState(null, '', url);
  }
}

document.addEventListener('click', event => {
  if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  const language = event.target.closest('[data-language]');
  const anchor = event.target.closest('a[href^="#"]');
  if (language) {
    event.preventDefault();
    setLanguage(language.dataset.language, true);
  }
  if (language || anchor) {
    document.querySelectorAll('.mobile-menu[open]').forEach(menu => menu.removeAttribute('open'));
  }
  if (anchor && !event.defaultPrevented) {
    const target = document.getElementById(anchor.getAttribute('href').slice(1));
    if (target instanceof HTMLElement) {
      // Closing the mobile menu hides its focused link; continue from the destination.
      if (!target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
      target.focus({ preventScroll: true });
    }
  }
});
addEventListener('hashchange', updateLanguageLinks);
addEventListener('popstate', () => setLanguage(new URLSearchParams(location.search).get('lang')));
colorScheme.addEventListener('change', updatePreviewLinks);
setLanguage(new URLSearchParams(location.search).get('lang'));

const demoToolbar = document.querySelector('.demo-toolbar');
const stageExample = document.getElementById('stage-example');
if (demoToolbar && stageExample) {
  demoToolbar.hidden = false;
  demoToolbar.addEventListener('click', event => {
    const button = event.target.closest('button[data-layout]');
    if (!button) return;
    stageExample.classList.toggle('is-overlap', button.dataset.layout === 'overlap');
    demoToolbar.querySelectorAll('button').forEach(item => {
      item.setAttribute('aria-pressed', String(item === button));
    });
  });
}
