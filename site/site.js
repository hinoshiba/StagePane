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
      "ja": "公開版をApp Storeで入手",
      "en": "Get the released app on the App Store"
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
      "ja": "見せたいものだけ、<br>ひとつのステージへ。",
      "en": "A clean stage for<br>everything you share."
    }
  },
  "hero-lead": {
    "html": {
      "ja": "複数の資料やアプリを、ひとつの共有ウインドウに。手元で配置・切り抜き・手書きを整え、会議アプリではStageだけを共有します。",
      "en": "Bring your documents and apps into one window for sharing. Arrange, crop, and annotate on your Mac, then share only the Stage in your meeting app."
    }
  },
  "preview-link": {
    "html": {
      "ja": "開発中の新UIを見る",
      "en": "Preview the new interface"
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
      "ja": "開発中の新UIです。App Store公開版とは一部の画面・機能が異なります。画像は合成サンプルで、実際の画面取得は行っていません。",
      "en": "This interface is in development. Some screens and features differ from the released App Store version. Images use synthetic samples; no real screen capture is running."
    }
  },
  "feature-title": {
    "html": {
      "ja": "整える。伝える。<br>ひとつのStageで。",
      "en": "Compose. Explain.<br>In one Stage."
    }
  },
  "feature-note": {
    "html": {
      "ja": "以下は開発中の新UIでの操作例です。App Store公開版とは一部異なります。",
      "en": "The examples below preview the interface in development and may differ from the released App Store version."
    }
  },
  "compose-title": {
    "html": {
      "ja": "重ねる、必要な範囲に切り抜く",
      "en": "Arrange and crop"
    }
  },
  "compose-copy": {
    "html": {
      "ja": "レイヤーを並べ、見せたい範囲を整えます。新UIでは一覧のドラッグで重なり順を変更。切り抜きは手元で下書きし、適用したときだけStageに反映します。",
      "en": "Arrange your layers and frame the parts you want to show. In the new interface, drag the layer list to change stacking order. Crop privately, then apply the draft to the Stage."
    }
  },
  "explain-title": {
    "html": {
      "ja": "描いて、拡大して伝える",
      "en": "Draw and magnify"
    }
  },
  "explain-copy": {
    "html": {
      "ja": "ペンや蛍光ペンで大事な場所を示し、消しゴムで整える。開発中の虫眼鏡では、細部を拡大して観客に見せられます。",
      "en": "Point out what matters with a pen or highlighter, then tidy up with the eraser. The magnifier in development lets you enlarge details for your audience."
    }
  },
  "curtain-title": {
    "html": {
      "ja": "ひと息つくときは、カーテン",
      "en": "Pause the view with Curtain"
    }
  },
  "curtain-copy": {
    "html": {
      "ja": "<kbd>⇧⌘H</kbd> ですぐにStageを覆い、次の内容を準備できます。画面取得を終了するときは「すべて停止」を使います。",
      "en": "Cover the Stage with <kbd>⇧⌘H</kbd> while you prepare what comes next. Use Stop All when you want to end capture."
    }
  },
  "draw-caption": {
    "html": {
      "ja": "手書きの道具はキャンバスのそばへ。観客には編集UIを含まない合成結果を表示します。",
      "en": "Keep drawing tools beside the Canvas. Your audience sees the composition without the editing controls."
    }
  },
  "settings-caption": {
    "html": {
      "ja": "Stageの形、背景、カーテン、ポインタをひとまとめに。編集用UIはmacOSの外観に自動で追従します。",
      "en": "Stage shape, background, curtain, and pointer settings stay together. The editor follows your Mac’s appearance automatically."
    }
  },
  "workflow-title": {
    "html": {
      "ja": "選んで、整えて、共有する。",
      "en": "Choose. Compose. Share."
    }
  },
  "step-1": {
    "html": {
      "ja": "追加する",
      "en": "Add your sources"
    }
  },
  "step-1-copy": {
    "html": {
      "ja": "「ソースを追加」から、ウインドウ・アプリ・画面をAppleの選択画面で選びます。",
      "en": "Choose Add Source, then select a window, app, or display in Apple’s picker."
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
  "plan-tools": {
    "html": {
      "ja": "配置・切り抜き・手書き・カーテン",
      "en": "Arrange, Crop, Draw, and Curtain"
    }
  },
  "plan-included": {
    "html": {
      "ja": "利用可",
      "en": "Included"
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
      "ja": "使う前に、知っておきたいこと。",
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
      "ja": "新UIの画面収録アクセスは必須ですか？",
      "en": "Is Screen Recording Access required in the new UI?"
    }
  },
  "faq-access-copy": {
    "html": {
      "ja": "任意です。初回に未許可なら案内を表示し、「許可する…」を選んだ場合だけ要求します。「StagePaneを使う」で続ければ、未許可でもピッカーで選んだ内容を共有できます。案内は起動のたびに繰り返しません。「画面共有について」の「Macの画面収録アクセスを確認…」から再確認できます。",
      "en": "It is optional. If access is not allowed on the first check, a guide appears; only Allow… requests it. Choose Continue to share picker-selected content without it. The guide does not repeat at each launch. Recheck from About Screen Sharing → Check Mac Screen Recording Access."
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
      "ja": "メニューバーのStagePaneアイコンからWorkspaceやStageを再表示できます。macOS側で共有が終了したレイヤーは「選び直す」で再接続し、配置と切り抜きを保てます。「解除」で削除したレイヤーは、ソースを追加し直してください。選択や取得開始のエラーはWorkspace内に表示し、閉じるか問題が解消するまで保持します。「もう一度試す」から再試行できます。",
      "en": "Use the StagePane menu-bar icon to reopen Workspace or Stage. If macOS ends sharing for a source, Select Again reconnects its retained layer with the same placement and crop. If you removed a layer, add its source again. Selection or capture-start errors remain in Workspace until dismissed or resolved. Use Try Again to retry."
    }
  },
  "faq-settings": {
    "html": {
      "ja": "新UIでは設定をどこから開きますか？",
      "en": "Where are settings in the new interface?"
    }
  },
  "faq-settings-copy": {
    "html": {
      "ja": "キャンバス上部の「Stage設定」で、形・背景・カーテン・ポインタを調整します。変更はStageへすぐ反映されます。「設定」（⌘,）は独立ウインドウで、一般設定、Pro、アプリ情報、プライバシー、画面共有の案内を確認できます。",
      "en": "Open Stage Settings above the Canvas to adjust shape, background, curtain, and pointer. Changes apply to the Stage immediately. Settings (⌘,) opens a separate window for general settings, Pro, app information, privacy, and screen-sharing guidance."
    }
  },
  "faq-contact": {
    "html": {
      "ja": "問い合わせや購入の相談は？",
      "en": "Where can I get help?"
    }
  },
  "faq-contact-copy": {
    "html": {
      "ja": "製品の問い合わせは <a class=\"contact-link\" href=\"mailto:support@hinoshiba.com\">support@hinoshiba.com</a> へ。購入・請求・返金は <a class=\"contact-link\" href=\"https://support.apple.com/billing\">Appleの購入サポート</a> をご利用ください。問題を報告するときはOS・アプリのバージョンと合成データでの再現手順を添え、実画面、私的なウインドウ名、会議URL、トークンなどは送らないでください。",
      "en": "Contact <a class=\"contact-link\" href=\"mailto:support@hinoshiba.com\">support@hinoshiba.com</a> for product help. For purchases, billing, and refunds, use <a class=\"contact-link\" href=\"https://support.apple.com/billing\">Apple’s purchase support</a>. Include OS and app versions and steps using synthetic content when reporting an issue. Do not send real screen frames, private window names, meeting URLs, tokens, or other private information."
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
      "ja": "ソースコードから試す",
      "en": "Build from source"
    }
  },
  "build-copy": {
    "html": {
      "ja": "StagePaneはApache License 2.0でソースコードを公開しています。ビルド方法はREADMEをご覧ください。ローカルの開発ビルドは公式配布版ではありません。",
      "en": "StagePane’s source code is available under Apache License 2.0. See the README for build instructions. Local development builds are not official distribution binaries."
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
      "ja": "次の画面共有を、<br>あなたのStageで。",
      "en": "Make your next screen share<br>your own Stage."
    }
  },
  "closing-copy": {
    "html": {
      "ja": "公式の公開版はMac App Storeで配信しています。",
      "en": "The official released app is available on the Mac App Store."
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
      "ja": "開発中のStagePane Workspace。レイヤー一覧とキャンバスを並べ、選択レイヤーの切り抜きとその他メニューを表示した合成サンプル",
      "en": "StagePane Workspace in development, with the layer list beside the Canvas and Crop and More controls for the selected layer. Synthetic sample."
    },
    "src": {
      "ja": "assets/screenshots/ja/workspace-light.webp",
      "en": "assets/screenshots/en/workspace-light.webp"
    }
  },
  "workspace-dark": {
    "srcset": {
      "ja": "assets/screenshots/ja/workspace-dark.webp",
      "en": "assets/screenshots/en/workspace-dark.webp"
    }
  },
  "workspace-zoom": {
    "aria-label": {
      "ja": "画像を拡大: 開発中のStagePane Workspace。レイヤー一覧とキャンバスを並べ、選択レイヤーの切り抜きとその他メニューを表示した合成サンプル",
      "en": "Enlarge image: StagePane Workspace in development, with the layer list beside the Canvas and Crop and More controls for the selected layer. Synthetic sample."
    }
  },
  "draw-image": {
    "alt": {
      "ja": "開発中の手書きモード。合成サンプルのキャンバスにペン・蛍光ペン・部分消去を表示",
      "en": "Draw mode in development, showing pen, highlighter, and partial erasing on a synthetic Canvas."
    },
    "src": {
      "ja": "assets/screenshots/ja/draw-light.webp",
      "en": "assets/screenshots/en/draw-light.webp"
    }
  },
  "draw-dark": {
    "srcset": {
      "ja": "assets/screenshots/ja/draw-dark.webp",
      "en": "assets/screenshots/en/draw-dark.webp"
    }
  },
  "draw-zoom": {
    "aria-label": {
      "ja": "画像を拡大: 開発中の手書きモード。合成サンプルのキャンバスにペン・蛍光ペン・部分消去を表示",
      "en": "Enlarge image: Draw mode in development, showing pen, highlighter, and partial erasing on a synthetic Canvas."
    }
  },
  "stage-settings-image": {
    "alt": {
      "ja": "開発中のStage設定。画面の形、背景、カーテン、ポインタをまとめたパネル",
      "en": "Stage Settings in development, with shape, background, curtain, and pointer controls."
    },
    "src": {
      "ja": "assets/screenshots/ja/stage-settings.webp",
      "en": "assets/screenshots/en/stage-settings.webp"
    }
  },
  "stage-settings-dark": {
    "srcset": {
      "ja": "assets/screenshots/ja/stage-settings-dark.webp",
      "en": "assets/screenshots/en/stage-settings-dark.webp"
    }
  },
  "stage-settings-zoom": {
    "aria-label": {
      "ja": "画像を拡大: 開発中のStage設定。画面の形、背景、カーテン、ポインタをまとめたパネル",
      "en": "Enlarge image: Stage Settings in development, with shape, background, curtain, and pointer controls."
    }
  },
  "meta-title": {
    "content": {
      "ja": "StagePane — 見せたいものだけ、ひとつのステージへ。",
      "en": "StagePane — A clean stage for everything you share."
    }
  },
  "meta-description": {
    "content": {
      "ja": "複数の資料やアプリをひとつの共有ウインドウに整えるmacOSアプリ。無料で4ソース、買い切りのProはアプリ側の件数制限なし。開発中の新UIも紹介しています。",
      "en": "Compose documents and apps in one macOS window for sharing. Free supports four sources; the one-time Pro purchase removes the app’s source limit. Preview the interface in development."
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
      "ja": "https://stagepane.hinoshiba.com/assets/screenshots/ja/workspace-light.webp",
      "en": "https://stagepane.hinoshiba.com/assets/screenshots/en/workspace-light.webp"
    }
  },
  "meta-image-alt": {
    "content": {
      "ja": "開発中のStagePane Workspaceの合成サンプル。App Store公開版とは一部異なります。",
      "en": "Synthetic preview of StagePane Workspace in development. Some details differ from the released App Store version."
    }
  },
  "canonical": {
    "href": {
      "ja": "https://stagepane.hinoshiba.com/",
      "en": "https://stagepane.hinoshiba.com/?lang=en"
    }
  }
};
const colorScheme = window.matchMedia('(prefers-color-scheme: dark)');
let currentLanguage = 'ja';

function updatePreviewLinks() {
  document.querySelectorAll('[data-preview]').forEach(link => {
    const kind = link.dataset.preview;
    const filename = colorScheme.matches
      ? kind + '-dark'
      : (kind === 'stage-settings' ? kind : kind + '-light');
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
