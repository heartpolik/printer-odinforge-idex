# Налаштування Orca Slicer для IDEX принтера

## Встановлення G-code

### 1. Стартовий G-code

Скопіюйте вміст файлу `orca_start_gcode.txt` або `orca_start_gcode_detailed.txt` в поле **Start G-code** в налаштуваннях принтера в Orca Slicer.

**Рекомендовано:** Використовуйте `orca_start_gcode_detailed.txt` для більш детального контролю.

### 2. Кінцевий G-code

Скопіюйте вміст файлу `orca_end_gcode.txt` в поле **End G-code** в налаштуваннях принтера в Orca Slicer.

## Параметри START_PRINT макросу

**Важливо:** `START_PRINT` (Klippain framework, `~/klippain_config/macros/base/start_print.cfg`,
619 рядків, не редагується напряму) — це stock однопрофільний макрос. Він приймає лише ОДНЕ
значення температури екструдера (`EXTRUDER_TEMP`, для активного на старті інструменту), і НЕ
має параметрів `EXTRUDER_TEMP0/1` чи `IS_EXTRUDER0/1_USED` — їх не існує, попередня версія
цього доку/gcode була написана під вигаданий інтерфейс.

### Параметри, які реально приймає START_PRINT (автоматично визначаються):
- `BED_TEMP` - температура столу
- `EXTRUDER_TEMP` - температура екструдера, що починає друк (`INITIAL_TOOL`)
- `INITIAL_TOOL` - початковий інструмент (0 або 1)
- `MATERIAL` - тип матеріалу (PLA, PETG, ABS, TPU)
- `SIZE` - розмір першого шару для адаптивного bed mesh (формат: min_x_min_y_max_x_max_y)
- `TOTAL_LAYER` - загальна кількість шарів

### Опціональні параметри:
- `Z_ADJUST` - корекція Z offset (для різних профілів PEI)
- `SOAK` - час прогріву столу в хвилинах (0 = вимкнено)
- `CHAMBER` - температура камери (0 = вимкнено)
- `CHAMBER_MAXTIME` - максимальний час нагріву камери в хвилинах
- `MESH` - назва профілю bed mesh для завантаження (порожній рядок = автоматичний)

### Прогрів другого сопла (IDEX-специфічне доповнення, 2026-07-23)

Другий тулхед (T1/Munin) прогрівається НЕ через параметр START_PRINT, а через окрему
змінну `extruder_temp1` на overridden `_MODULE_EXTRUDER_HEATING` (доданo в `odin/macros/start_print.cfg`,
не чіпає framework-файл). Start g-code встановлює її ПЕРЕД викликом START_PRINT:

```
SET_GCODE_VARIABLE MACRO=_MODULE_EXTRUDER_HEATING VARIABLE=extruder_temp1 VALUE=<temp або 0>
```

Якщо `extruder_temp1 > 0`, `_MODULE_EXTRUDER_HEATING` додатково прогріває `extruder1` через
`ACTIVATE_EXTRUDER` (без фізичного руху каретки — лише нагрів) одразу після нагріву основного
сопла, і повертає активний екструдер назад. Це дозволяє T0<->T1 перемикання під час друку без
очікування нагріву. Обидва готові файли (`orca_start_gcode.txt`,
`orca_start_gcode_detailed.txt`) вже роблять це автоматично на основі `is_extruder_used[1]`.

## Послідовність дій START_PRINT

Послідовність дій визначається змінною `startprint_actions` в `odin/variables.cfg`:

1. `idex_reset` - скидання стану попереднього друку: T0 активний, без офсету T1 (odin/macros/idex.cfg)
2. `bed_soak` - прогрівання столу
3. `extruder_preheating` - попереднє нагрівання активного (T0) сопла до безпечної температури
4. `chamber_soak` - прогрівання камери (якщо налаштовано)
5. `tilt_calib` - Z_TILT
6. `extruder_heating` - нагрів сопла INITIAL_TOOL до температури друку, другого сопла до `extruder_temp1`
   (або вимкнення, якщо воно не використовується) - odin/macros/start_print.cfg
7. `z_offset` - калібрування Z offset
8. `bedmesh` - вимірювання bed mesh (на T0, probe тільки на ньому)
9. `idex_initial_tool` - перемикання на INITIAL_TOOL
10. `primeline` - лінія прочистки

`purge` і `clean` тимчасово вимкнені (див. коментар у odin/variables.cfg).

## Важливі зауваження

1. **Probe тільки на T0**: Всі операції з probe (homing, bed mesh, Z calibration) виконуються виключно з активованим T0.

2. **IDEX режими**: 
   - `primary` - незалежне управління каретками
   - `mirror` - дзеркальне відображення
   - `copy` - копіювання

3. **Ретракт при парковці**: При перемиканні інструментів автоматично виконується ретракт для запобігання перегріву пластику.

4. **Матеріали**: Підтримуються матеріали: PLA, PETG, ABS, TPU. Параметри (pressure advance, retraction тощо) налаштовуються автоматично.

## Налаштування в Orca Slicer

1. Відкрийте налаштування принтера
2. Перейдіть до розділу "Machine G-code"
3. Вставте стартовий G-code з файлу `orca_start_gcode_detailed.txt`
4. Вставте кінцевий G-code з файлу `orca_end_gcode.txt`
5. Збережіть налаштування

## Приклад використання

Для друку з одним інструментом (T0):
- `INITIAL_TOOL=0` визначається автоматично через `initial_tool` (Orca placeholder)
- `is_extruder_used[1]` = false → `extruder_temp1=0` → друге сопло НЕ прогрівається

Для друку з двома інструментами:
- `INITIAL_TOOL` = перший активний інструмент
- `is_extruder_used[1]` = true → друге сопло прогрівається заздалегідь до `first_layer_temperature[1]`

## Синтаксис (2026-07-23 фікс)

Orca Slicer НЕ використовує Jinja2 (`{% set %}`, `{% if %}`) — це своя проста мова плейсхолдерів:
`{if умова}...{elsif умова}...{else}...{endif}` для розгалужень, `{local ім'я = значення}` для
змінних (scope — поточний шаблон), `{ім'я}` / `{масив[0]}` для підстановки значень. Попередня
версія `orca_start_gcode*.txt` була написана Jinja2-синтаксисом (як у Klipper-макросах) і не
парсилась Orca взагалі — виправлено в обох файлах.

Джерело: [OrcaSlicer built-in placeholders wiki](https://github.com/OrcaSlicer/OrcaSlicer/wiki/built_in_placeholders_variables)

