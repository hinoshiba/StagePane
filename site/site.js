const translations = {
  "t98": {
    "html": {
      "ja": "選択した画面と手書きは、Mac上でStageを表示するために処理します。画面の配信は、利用者が選んだ会議アプリが行います。",
      "en": "Selected screen content and drawings are processed on your Mac to display the Stage. Your chosen meeting app handles screen-sharing transmission."
    }
  },
  "t99": {
    "html": {
      "ja": "設定はMacに保存します。保存するのはStageの形状と外観、ウインドウの動作、セーフエリアガイドとStagePaneマークの設定、ポインタのスタイル・大きさ・色・グロー、カーテンの文言と文字の大きさ、手書きツールの設定、レイヤー一覧の幅、Macの画面収録アクセスの初回確認が済んだかどうか、およびWorkspace・Stage・設定・Pro・画面共有の案内・Macの画面収録アクセスの各ウインドウの位置と大きさです。許可状態そのものは保存せず、macOSから確認します。Mac App Store版はこれに加えて、App Storeの評価依頼を表示する時期の判断にだけ使うローカルな3つの値（成功したセッションの回数、その最初の日付、評価依頼を最後に表示したアプリのバージョン）を保存します。画面、ソース名、Stage上のソースの配置、手書きは保存しません。手書きは作業中のメモリで扱い、「すべて停止」または終了で破棄します。「画像をコピー」はシステムのクリップボードへPNGを置き、ほかのアプリから参照できます。「PNGを保存」は選択した場所へ書き込みます。不要な画像は利用者が削除できます。",
      "en": "Preferences are stored on your Mac: the Stage shape and appearance, window behavior, the safe-area guide and StagePane mark settings, the pointer style, size, color, and glow, the Curtain message and its text size, drawing tool settings, the layer list width, whether the first Mac Screen Recording Access check has been completed, and the position and size of the Workspace, Stage, Settings, Pro, screen-sharing guide, and Mac Screen Recording Access windows. The access status itself is read from macOS, not saved by StagePane. The Mac App Store build additionally stores three local values used only to decide when to show the App Store rating prompt: a count of successful sessions, the date of the first one, and the app version in which the prompt was last shown. Screen content, source names, the Stage layout of your sources, and drawings are not stored. Drawings are held in memory during use and are discarded when you choose Stop All or quit. Copy Image places a PNG on the system clipboard, where other apps may access it; Save PNG writes to your chosen location. You can delete saved images when no longer needed."
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
      "ja": "できること",
      "en": "Features"
    }
  },
  "how": {
    "html": {
      "ja": "使い方",
      "en": "How it works"
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
      "en": "A macOS app for screen sharing"
    }
  },
  "hero-title": {
    "html": {
      "ja": "見せたいものだけ、<br>ひとつの共有画面に。",
      "en": "Share what matters.<br>In one window."
    }
  },
  "hero-lead": {
    "html": {
      "ja": "資料とアプリのデモを、好きな大きさ・配置でひとつに。会議では専用のStageウインドウを共有し、手元の作業と見せる内容を分けられます。",
      "en": "Bring slides and app demos together in the layout you want. Share the dedicated Stage window in your meeting, with your private workspace kept separate."
    }
  },
  "preview-link": {
    "html": {
      "ja": "共有の仕組みを見る",
      "en": "See how it works"
    }
  },
  "compatibility": {
    "html": {
      "ja": "macOS 14以降 · Apple Silicon / Intel",
      "en": "macOS 14 or later · Apple Silicon / Intel"
    }
  },
  "preview-caption": {
    "html": {
      "ja": "説明資料とアプリのデモを、並べて共有。画面はサンプルです。",
      "en": "Slides and an app demo, shared side by side. Sample content shown."
    }
  },
  "explain-title": {
    "html": {
      "ja": "大事なところに、注目を。",
      "en": "Bring details into focus."
    }
  },
  "explain-copy": {
    "html": {
      "ja": "ペンや蛍光ペンで示し、虫眼鏡で細部を拡大。視線を集めて、説明をわかりやすく。",
      "en": "Draw or highlight what matters, and magnify small details. Help everyone follow your explanation."
    }
  },
  "curtain-title": {
    "html": {
      "ja": "準備する間は、カーテンを。",
      "en": "Take a moment behind the Curtain."
    }
  },
  "curtain-copy": {
    "html": {
      "ja": "Stageをさっと覆い、次の内容を準備。整ったら、また続きを見せられます。",
      "en": "Cover the Stage while you prepare what comes next. Reveal it when you are ready to continue."
    }
  },
  "workflow-title": {
    "html": {
      "ja": "<span class=\"phrase\">選ぶ。</span><span class=\"phrase\">整える。</span><span class=\"phrase\">共有する。</span>",
      "en": "Choose. Compose. Share."
    }
  },
  "step-1": {
    "html": {
      "ja": "ウインドウを選ぶ",
      "en": "Choose your windows"
    }
  },
  "step-1-copy": {
    "html": {
      "ja": "「ソースを追加」から、見せたい資料やアプリのウインドウをAppleの選択画面で選びます。",
      "en": "Use Add Source and Apple’s picker to choose the document or app windows you want to show."
    }
  },
  "step-2": {
    "html": {
      "ja": "手元で整える",
      "en": "Compose on your Mac"
    }
  },
  "step-2-copy": {
    "html": {
      "ja": "Workspaceで配置や表示範囲を調整します。準備中はカーテンで観客向けの映像を隠せます。",
      "en": "Arrange and crop in the Workspace. Keep the audience view covered with Curtain while you prepare."
    }
  },
  "step-3": {
    "html": {
      "ja": "Stageを共有する",
      "en": "Share the Stage"
    }
  },
  "step-3-copy": {
    "html": {
      "ja": "会議アプリのウインドウ共有で「StagePane Stage」を選びます。共有対象を確認してからカーテンを開きます。",
      "en": "Select “StagePane Stage” in your meeting app’s window-sharing picker. Confirm the selected window, then open Curtain."
    }
  },
  "plan-title": {
    "html": {
      "ja": "無料で始める。必要に応じてProへ。",
      "en": "Start free. Add Pro when you need it."
    }
  },
  "plan-caption": {
    "html": {
      "ja": "無料版とStagePane Pro",
      "en": "Free and StagePane Pro"
    }
  },
  "plan-feature": {
    "html": {
      "ja": "機能",
      "en": "Feature"
    }
  },
  "plan-free": {
    "html": {
      "ja": "無料版",
      "en": "Free"
    }
  },
  "plan-pro": {
    "html": {
      "ja": "Pro",
      "en": "Pro"
    }
  },
  "plan-sources": {
    "html": {
      "ja": "同時に使えるソース",
      "en": "Simultaneous sources"
    }
  },
  "plan-four": {
    "html": {
      "ja": "4件",
      "en": "Four"
    }
  },
  "plan-unlimited": {
    "html": {
      "ja": "アプリ側の上限なし",
      "en": "No app-imposed limit"
    }
  },
  "plan-mark": {
    "html": {
      "ja": "StagePaneロゴ",
      "en": "StagePane mark"
    }
  },
  "plan-shown": {
    "html": {
      "ja": "表示",
      "en": "Shown"
    }
  },
  "plan-optional": {
    "html": {
      "ja": "表示／非表示",
      "en": "Optional"
    }
  },
  "plan-note": {
    "html": {
      "ja": "Proは買い切りです。利用できるソース数はMacの性能とOSの制約に依存します。価格と通貨はApp Storeとアプリ内の購入画面で確認できます。",
      "en": "Pro is a one-time purchase. The number of usable sources depends on your Mac’s performance and operating-system limits. Check the App Store and the in-app purchase screen for the price in your currency."
    }
  },
  "faq-title": {
    "html": {
      "ja": "よくある質問",
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
      "ja": "カーテンを閉じると取得も止まりますか？",
      "en": "Does closing Curtain stop capture?"
    }
  },
  "faq-curtain-copy": {
    "html": {
      "ja": "カーテンは観客向けの映像を覆い、画面取得は継続します。「すべて停止」は取得を終了し、再接続待ちを含む全レイヤーを削除します。1件だけ一時的に隠す場合は、そのレイヤーの「非表示」を使います。",
      "en": "Curtain covers the audience view while capture continues. Stop All ends capture and removes every layer, including disconnected layers. To temporarily hide one source, use Hide on that layer."
    }
  },
  "faq-crop": {
    "html": {
      "ja": "切り抜きやソース選択の範囲は？",
      "en": "What do source selection and cropping include?"
    }
  },
  "faq-crop-copy": {
    "html": {
      "ja": "各ソースはAppleの選択画面で、その取得セッション用に許可します。アプリを選ぶと複数ウインドウが含まれる場合があるため、範囲を絞るには1つのウインドウを選びます。切り抜きはStageの表示範囲を変えるもので、選択したソース全体の取得範囲は変わりません。",
      "en": "You approve each source in Apple’s picker for that capture session. Choosing an app can include several windows; choose a single window for a narrower scope. Cropping changes the area shown on the Stage, not the scope of the captured source."
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
  "faq-recovery": {
    "html": {
      "ja": "ウインドウや映像を見失ったときは？",
      "en": "How do I recover a window or source?"
    }
  },
  "faq-recovery-copy": {
    "html": {
      "ja": "メニューバーのStagePaneアイコンからWorkspaceやStageを再表示できます。共有が終了したレイヤーは「選び直す」で再接続すると、配置と切り抜きを保てます。ソース選択や取得開始のエラーは、Workspace内の案内から再試行できます。",
      "en": "Reopen Workspace or Stage from the StagePane menu bar icon. Use Select Again on an ended source to reconnect while keeping its layout and crop. Source-selection or capture-start errors can be retried from the notice in Workspace."
    }
  },
  "privacy-title": {
    "html": {
      "ja": "画面の扱いとプライバシー",
      "en": "Screen content and privacy"
    }
  },
  "privacy-summary": {
    "html": {
      "ja": "選択した画面はMac上で処理します。会議への配信は、利用者が選んだ会議アプリが行います。StagePaneにアカウントは不要で、画像はコピーやPNG保存を選んだときだけ残ります。",
      "en": "Selected screen content is processed on your Mac. Your meeting app handles transmission to the meeting. StagePane needs no account, and images remain only when you choose to copy an image or save a PNG."
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
  "closing-title": {
    "html": {
      "ja": "次の画面共有を、<br>もっと伝わる時間に。",
      "en": "Make your next screen share<br>easier to follow."
    }
  },
  "closing-copy": {
    "html": {
      "ja": "まずは無料で。4つのソースを、あなたのStageに。",
      "en": "Start free. Bring up to four sources into your Stage."
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
      "ja": "assets/screenshots/ja/product-workspace-light.webp",
      "en": "assets/screenshots/en/product-workspace-light.webp"
    }
  },
  "workspace-dark": {
    "srcset": {
      "ja": "assets/screenshots/ja/product-workspace-dark.webp",
      "en": "assets/screenshots/en/product-workspace-dark.webp"
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
      "ja": "StagePane — 見せたいものだけ、ひとつの共有ウインドウに。",
      "en": "StagePane — Share what matters. In one window."
    }
  },
  "meta-description": {
    "content": {
      "ja": "資料とアプリを自由に並べて、ひとつの共有ウインドウに。選んだウインドウだけを共有し、通知や手元の作業と分けられるmacOSアプリ。4ソースまで無料。",
      "en": "Arrange slides and apps in one shareable window. Choose individual windows to keep other apps’ notifications and private work outside your share. Free for up to four sources on macOS."
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
      "ja": "https://stagepane.hinoshiba.com/assets/screenshots/ja/product-stage.webp",
      "en": "https://stagepane.hinoshiba.com/assets/screenshots/en/product-stage.webp"
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
  "audience-label": {
    "html": {
      "ja": "相手に見える画面",
      "en": "What your audience sees"
    }
  },
  "privacy-benefit-title": {
    "html": {
      "ja": "通知や個人メモを、<br>共有の外に。",
      "en": "Keep notifications<br>and private work private."
    }
  },
  "privacy-benefit-copy": {
    "html": {
      "ja": "見せたいウインドウを個別に選び、会議ではStageだけを共有。選択していない別アプリの通知や、デスクトップでの作業を混ぜずに見せられます。",
      "en": "Choose individual windows, then share only the Stage in your meeting app. Notifications from other apps and work outside those windows stay out of the composition."
    }
  },
  "sharing-condition": {
    "html": {
      "ja": "画面全体やアプリ全体を選ぶと、共有される範囲も広がります。選択したウインドウ内の通知やダイアログは表示されることがあります。",
      "en": "Choosing an entire display or app broadens what is shared. Notifications and dialogs within a selected window may still appear."
    }
  },
  "diagram-label": {
    "aria-label": {
      "ja": "ウインドウを個別に選んだ場合の共有範囲",
      "en": "Sharing scope when you select individual windows"
    }
  },
  "chosen-windows": {
    "html": {
      "ja": "選んだウインドウ",
      "en": "Windows you choose"
    }
  },
  "sample-slides": {
    "html": {
      "ja": "説明資料",
      "en": "Slides"
    }
  },
  "sample-demo": {
    "html": {
      "ja": "アプリのデモ",
      "en": "App demo"
    }
  },
  "shared-window": {
    "html": {
      "ja": "会議で共有",
      "en": "Share in your meeting"
    }
  },
  "private-label": {
    "html": {
      "ja": "選ばなかったものは、手元に",
      "en": "Everything else stays with you"
    }
  },
  "private-notifications": {
    "html": {
      "ja": "別アプリの通知",
      "en": "Other apps’ notifications"
    }
  },
  "private-notes": {
    "html": {
      "ja": "個人メモ",
      "en": "Private notes"
    }
  },
  "private-desktop": {
    "html": {
      "ja": "デスクトップ",
      "en": "Your desktop"
    }
  },
  "layout-eyebrow": {
    "html": {
      "ja": "見せるためのレイアウト",
      "en": "A layout for your audience"
    }
  },
  "layout-title": {
    "html": {
      "ja": "資料とデモを、<br>並べて伝える。",
      "en": "Your slides and demo.<br>Better together."
    }
  },
  "layout-copy": {
    "html": {
      "ja": "説明資料のとなりに、アプリの動きを。比較したい2つの資料も、ひとつの画面に。大きさ・位置・重なりを整え、必要な部分だけを切り抜いて見せられます。",
      "en": "Put a live app demo beside your slides, or compare two documents in one view. Resize, position, layer, and crop your content for the audience."
    }
  },
  "layout-detail": {
    "html": {
      "ja": "手元のウインドウ配置はそのまま。共有するStageの中だけで、見やすく整えられます。",
      "en": "Keep your desktop arranged for you. Compose the Stage for everyone else."
    }
  },
  "workspace-caption": {
    "html": {
      "ja": "手元で整えるWorkspace。編集用の道具は、Stageには映りません。",
      "en": "Your Workspace for composing. Editing controls do not appear in the Stage."
    }
  },
  "tools-title": {
    "html": {
      "ja": "<span class=\"phrase\">説明を、</span><span class=\"phrase\">わかりやすく。</span>",
      "en": "Make your point clear."
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
      "ja": "StagePaneは画面内容をクラウドに送信しません。StagePaneのアカウントも不要。会議への配信は、お使いの会議アプリが行います。",
      "en": "StagePane processes screen content locally, with no cloud upload or StagePane account. Your meeting app handles transmission to your audience."
    }
  },
  "plan-common": {
    "html": {
      "ja": "配置・切り抜き・手書き・虫眼鏡・カーテンは、無料版でも使えます。",
      "en": "Arranging, cropping, drawing, magnifying, and the Curtain are included in the free version."
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
  "stage-image": {
    "alt": {
      "ja": "説明資料と予約アプリのデモを左右に並べたStageの表示例",
      "en": "Sample Stage with presentation slides and a booking app demo side by side"
    },
    "src": {
      "ja": "assets/screenshots/ja/product-stage.webp",
      "en": "assets/screenshots/en/product-stage.webp"
    }
  },
  "stage-zoom": {
    "href": {
      "ja": "assets/screenshots/ja/product-stage.webp",
      "en": "assets/screenshots/en/product-stage.webp"
    },
    "aria-label": {
      "ja": "画像を拡大: 説明資料と予約アプリのデモを左右に並べたStageの表示例",
      "en": "Enlarge image: Sample Stage with presentation slides and a booking app demo side by side"
    }
  }
};
const colorScheme = window.matchMedia('(prefers-color-scheme: dark)');
let currentLanguage = 'ja';

function updatePreviewLinks() {
  document.querySelectorAll('[data-preview]').forEach(link => {
    const kind = link.dataset.preview;
    const filename = kind + (colorScheme.matches ? '-dark' : '-light');
    link.href = 'assets/screenshots/' + currentLanguage + '/' + filename + '.webp';
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
  document.querySelectorAll('[data-language]').forEach(link => {
    link.href = '?lang=' + link.dataset.language + location.hash;
  });
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
  const language = event.target.closest('[data-language]');
  const anchor = event.target.closest('a[href^="#"]');
  if (language) {
    event.preventDefault();
    setLanguage(language.dataset.language, true);
  }
  if (language || anchor) {
    document.querySelectorAll('.mobile-menu[open]').forEach(menu => menu.removeAttribute('open'));
  }
  if (anchor && !event.defaultPrevented && event.button === 0
      && !event.metaKey && !event.ctrlKey && !event.shiftKey && !event.altKey) {
    const target = document.getElementById(anchor.getAttribute('href').slice(1));
    if (target instanceof HTMLElement) {
      // Closing the mobile menu hides its focused link; continue from the destination.
      if (!target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
      target.focus({ preventScroll: true });
    }
  }
});
addEventListener('popstate', () => setLanguage(new URLSearchParams(location.search).get('lang')));
colorScheme.addEventListener('change', updatePreviewLinks);
setLanguage(new URLSearchParams(location.search).get('lang'));
