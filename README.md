# Math Galaxy — v13

Офлайн обучающая аркада на Godot 4.7.2 standard, GDScript.
Основная сцена: `scenes/Main.tscn`. Откройте `project.godot`, дождитесь импорта и нажмите F6/F5.

## Техническая стабилизация

`SaveManager.gd` централизует чтение, валидацию и миграцию профиля до схемы 13.
Старые поля, кристаллы, статистика и неизвестные поля сохраняются; отсутствующие
поля добавляются. LearningEngine по-прежнему отделяет legacy-агрегаты от новых
доказательств знания. Подсказки, демонстрации и варианты ответа не дают
самостоятельного доказательства.

Запись идёт в соседний `.tmp`, выполняются flush и повторная проверка JSON,
затем сохраняется предыдущий валидный профиль в `.bak` и выполняется rename.
При повреждении основной копии используется `.bak` с предупреждением.
Перед заменой нечитаемый оригинал копируется в `.unreadable_<timestamp>`.
Если обе копии непригодны, показывается предупреждение и автоматическая запись
блокируется: восстановите JSON через родительский экран. Импорт и явный сброс
создают резервную копию. Форматы новее 13 не загружаются как действующие профили.
Сохранения находятся в Godot `user://math_galaxy_progress.json`.

`MissionManager.gd` рассчитывает фазы и масштабирует их под родительскую длительность.
Main сохраняет UI и координацию боя. Уже существующий RewardManager отвечает
за покупки и однократное начисление наград; его логика не дублируется.

## Windows и Android

1. Установите Godot 4.7.2 standard и соответствующие export templates.
2. Windows: Project → Export → Add → Windows Desktop; выберите путь вне исходников,
   выполните Export Project. Экспортные пресеты в репозитории не настроены.
3. Android: установите Android SDK и JDK согласно документации установленного Godot;
   задайте пути в Editor Settings → Export → Android. Добавьте Android preset,
   уникальный package name, debug keystore для тестов; для release — отдельный ключ.
   Не добавляйте ключи и пароли в Git. Экспортируйте APK и установите на устройство.
4. Проверьте landscape (orientation=0), viewport 1280×720 и canvas_items stretch.
   Обработка touch как mouse включена явно. Боевой ввод, мастерская и PIN используют
   кнопки; LineEdit/TextEdit и вызовов экранной клавиатуры в проекте нет.

## Автоматические проверки

В PowerShell из корня проекта:

```powershell
./tests/run_tests.ps1 -Godot 'D:\Program Files\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
```

Скрипт изолирует APPDATA в `.test-user`, запускает импорт и все `test_*.gd`,
проверяет ошибки, код выхода и маркер завершения. Для отдельных тестов используйте
`--headless --path . --script tests/test_storage_mission.gd` с изолированной APPDATA.
Не запускайте тесты на настоящем пользовательском профиле.

Покрытие: генераторы пяти миров и уровней, правильность разложения подсказок,
четыре уникальных варианта, диапазоны чисел, навыки, интервалы и mastery,
мастерская, пауза подсказок, фазы миссии, поражение, награды и защита от повторной
выдачи, ангар, родительская диагностика и UI, legacy и повреждённые сохранения.

## Ручной smoke checklist

- F5: открыть каждый мир, уровни, мастерскую, HANGAR и родительский экран.
- В бою проверить цифры, удаление, ответ, четыре варианта, пропуск и тайм-аут.
- Открыть подсказку: таймеры стоят; закрыть — продолжаются; энергия списывается.
- Проверить все фазы, награду за успех и отсутствие награды при выходе/поражении.
- Купить/экипировать предмет, перезапустить; проверить баланс и выбор.
- На копии профиля проверить legacy JSON, повреждение основного файла и восстановление
  из `.bak`; затем повредить обе копии, проверить предупреждение, сохранность файлов,
  блокировку автозаписи и восстановление через импорт родительского экрана.
- На Android проверить одинарные касания, прокрутку, отсутствие двойных ответов,
  отсутствие системной клавиатуры, уход в фон/возврат и широкие/узкие экраны.

## Проверено и ограничения

31 октября 2026: Godot 4.7.2 headless, импорт без parse errors, восемь наборов тестов.
Godot сообщает `Failed to read the root certificate store` в этом окружении;
игра и проверки офлайн. Android APK, экспорт Windows, визуальный smoke и касания
на физическом устройстве не проверены. Export presets и SDK автоматически не создаются.
Rename и резервирование защищают от незавершённой записи приложения, но не гарантируют
сохранность при аппаратном сбое накопителя. Одновременная запись двумя экземплярами
игры не поддерживается. Main всё ещё отвечает за UI и бой: полного переписывания нет.

Изменены: project.godot, scripts/Main.gd, scripts/ParentData.gd,
scripts/ParentDashboard.gd, scripts/RewardManager.gd, tests/test_parent.gd, README.md.
Добавлены: scripts/SaveManager.gd, scripts/MissionManager.gd,
tests/test_storage_mission.gd, tests/run_tests.ps1 и Godot UID новых GDScript.
Архивы по запросу пользователя не создаются.

## Язык интерфейса

На главном экране справа вверху выберите **English** или **Українська**. Перевод применяется сразу к меню и следующим открываемым экранам. По умолчанию используется английский. Выбор сохраняется в `user://language.cfg` отдельно от прогресса, поэтому сброс или импорт учебных данных его не меняет.

Проверка вручную: переключите язык, откройте выбор уровней, мастерскую, бой, ангар и родительскую панель. Перезапустите игру и убедитесь, что выбранный язык сохранился; затем переключитесь обратно. Переводы находятся в `scripts/TranslationCatalog.gd`, автоматически включаемом в экспорт через preload.


### Paired worlds and practice modes

World display order is multiplication / division at each difficulty: table facts,
two digits by one digit, three digits by one digit, then two digits by two digits
and advanced exact division. Stable internal world IDs are `1, 6, 2, 7, 3, 8, 4, 5`.
Each skill has a choice sublevel (exactly 5 seconds per question), followed by a
numeric reinforcement sublevel. Both modes require their own completion evidence;
choice answers do not count as independent mastery. World cards use a horizontal single-row strip with arrows, scrollbar, wheel
and touch scrolling. Sublevels use a responsive grid of location cards.
Version 14 migrates old completed sublevels to both halves and retains existing
world IDs, statistics and parent timing settings. World overview paintings and dedicated location illustrations are stored in
`assets/locations/`; earlier vector drafts remain in `assets/worlds/`.


### Location cards and independent world starts

Sublevels now use a responsive grid with separate location art, skill title, mode
instructions and completion status. Each choice/input pair shares a location.
Each location has its own full painting under `assets/locations/world_N/`;
the selected painting is used as the mission background and combat scenery.
There are 56 distinct location images across the eight worlds. A choice/input
pair shares one location; different skills never share an image.
Division world portraits and menus use the new painted art.

Parent dashboard → Settings → **Start each world independently** opens only the
first sublevel of every world; sublevels within each world remain sequential.
The option saves immediately and survives timing saves, restoring default timing,
profile reloads and imports. It defaults to off. Choice rounds remain 5 seconds;
parent timing controls apply to typed answers.


### Fleet, arsenal and single-monster encounters

The hangar contains 13 ships (10 new), 10 independently equipped weapons
(7 new) and the encounter roster contains 13 species (10 new). Ships provide
armor, reactor capacity and a damage bonus. Weapon draw cannot exceed
the reactor rating; switching to a smaller ship safely selects the free laser.
Previously purchased hulls and balances remain intact. No save reset is needed.

A sublevel fights one random monster from its difficulty pool. Phase changes
never heal or replace it. Hits show traveling projectiles, damage numbers,
a trailing health bar, flashes, accumulated scorch marks, glowing cracks and
embers. A dead monster stays defeated until the results screen.

`FleetBalance.gd` owns the tuning. The curriculum ordinal follows the displayed
world order; its reference budget is ordinal × 360 × 0.8 (two evidence missions
per sublevel, with 20% held back). Monster HP is 10 times the strongest compatible
ship/weapon damage affordable within that budget, or 12 times for a final.
The actual wallet and selected equipment never increase monster HP. Effective
damage is capped at the reference damage, preserving the educational minimum,
and focus assistance sets a damage floor that keeps any loadout within 18
correct hits (22 on finals). Misses do not reduce monster HP; combat continues
until victory or retreat. Existing independent-learning requirements still apply.
Extra hits beyond the mission target do not generate extra base crystals.

Paid ships cost 1,200–17,500 crystals; weapons cost 1,000–15,500.
Battery/repair upgrades cost 2,200/2,600. Regular rewards remain 10–15 per
correct answer (first 10/12 only), +40 completion and existing daily/achievement
bonuses. The first purchase therefore requires several successful missions,
and two perfect first missions cannot buy either a ship or a weapon.
Armor reduces the 20-point enemy hit by 0–9; shield regeneration is unchanged.

Run `tests/run_tests.ps1` for encounter math across every curriculum level and
compatible loadout, purchase/equipment migration, reactor restrictions, enemy
persistence, answer timing, saves, and the existing learning/UI suites.
