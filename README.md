# Math Galaxy v0.11 - UI polish and layout fixes

Based on v0.10. Keeps MathEngine and progress data format unchanged.

## Fixes
- Raised world card captions to avoid extending below the card.
- Brighter emerald mission button and more saturated reusable sci-fi buttons.
- Timer anchored inside the question row; question centered independently.
- Same cyan palette for answer choices and keypad.
- Removed the word ANSWER from the numeric display.
- Five new RGBA battle backdrops with gradual fade at the bottom and edges.
- Corrected duplicated FANCY and caption declarations carried over in the archived keypad.
- Correct Label theme override API.

## Update
Copy the contents into your project folder. Keep your existing .git and .godot folders. Start Godot and test with F5, in both choice and numeric modes. Review the Debugger for warnings/errors before committing.

## Limitations
Not runtime-tested in Godot in this environment. The existing sprites are retained; visual comparison with the earlier concept art remains a separate future art task.

## v11 — ангар и награды

В меню добавлена кнопка HANGAR. Доступны две окраски существующего корабля
(180/300 кристаллов), запас стартовой энергии +15 (220) и ремонт +15 щита
один раз за миссию (260). Покупки одноразовые; окраску нужно экипировать.
Улучшения не меняют LearningEngine, условия mastery и доказательства знаний.

Кристаллы за ответы остаются предварительными до успешного завершения миссии.
Дополнительно: завершение +40, первый успех за день UTC +30, самостоятельный
ответ на ранее ошибочный пример +25 за миссию, улучшение лучшей точности мира
+30 (не менее 10 ответов). Эти бонусы не требуют высокой скорости.
Пять достижений дают по +25 один раз. Личные рекорды хранят лучшую точность
(от 10 ответов) и число правильных ответов по каждому миру.
При поражении или выходе наград за эту миссию нет.

Схема сохранения 11 мягко добавляет rewards, сохраняя прежние кристаллы,
учебные данные и историю. Порядковый номер миссии сохраняется при старте;
последний рассчитанный номер защищает от повторной выдачи. Баланс, покупки,
достижения и рекорды записываются вместе через существующее атомарное сохранение.
Покупка и экипировка откатываются при ошибке записи.

Изменённые файлы: scripts/Main.gd, scripts/ParentData.gd,
scripts/SpaceScene.gd, .gitignore, README.md.
Добавлены scripts/RewardManager.gd, scripts/Hangar.gd,
tests/test_rewards.gd, tests/test_hangar.gd и их Godot UID.

Проверено в Godot 4.7.2 headless: импорт, тесты rewards, hangar, mastery,
progression, parent, parent_ui. Для проверок APPDATA перенаправлялась
в .test-user внутри проекта, реальные пользовательские сохранения не затрагивались.
Godot сообщает об ошибке чтения системного хранилища сертификатов;
офлайн тесты завершаются успешно. Android и визуальная проверка на устройстве
не выполнялись. Более короткие миссии могут давать меньшие рекорды количества
ответов; это не влияет на учебный прогресс.

Ручная проверка:
1. F5 → HANGAR: проверить прокрутку витрины и недоступность дорогих покупок.
2. Завершить миссию, проверить расшифровку награды и новый баланс.
3. Купить и экипировать корпус, перезапустить игру: цвет и остаток сохраняются.
4. Купить энергию/ремонт: стартовая энергия 65; ремонт даёт +15 щита только раз.
5. Проиграть или выйти: баланс не увеличивается, достижения не выдаются.
6. Повторно открыть ангар и перезапустить: одноразовые награды не повторяются.
7. Проверить старое сохранение и экспорт/импорт через родительский экран.

Архив не создавался по запросу пользователя.
