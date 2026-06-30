# Anti-patterns - What Breaks the Format

Each anti-pattern shows a broken response and names the breakage.

## prose wall

Когда голова уставшая, ты даешь расплывчатый запрос, и каша на входе
превращается в масштабированную кашу на выходе, которая еще и выглядит
убедительно, поэтому вечером лучше не делегировать агенту ничего важного.

(long sentences glued with commas - the eye has nothing to anchor on;
the reader must parse grammar instead of scanning structure)

## caveman compression

уставшая голова => расплывчатый запрос => каша x10

(the `=>` chain needs decoding - context is thrown away; arrows replaced the
explanation instead of marking it; unfold chains like this into children)

## markdown noise

## Принцип
**Claude – усилитель состояния**, не компенсатор.
| Состояние | Выход |
|-----------|-------|
| Свежая    | рычаг |

(headers, bold, and a table for two facts - decoration over signal)

## periods and capitals on children

Claude – усилитель состояния.
  Свежая голова дает четкий контекст.
  Модель возвращает рычаг.

(every line starts capital and ends with a period - the eye loses the
hierarchy; capital letters belong to island roots only, line break is the period)

## echo without context

чтение: 30m мертво, 3h заебись

(a real failure case: even the author of the original note did not understand
this echo of his own words; the line must stand on its own - unfold it using
context you actually have, never invent it:
daily 30-minute reading never sticks, one long coffeeshop session works)

## fake hierarchy - children that do not elaborate the parent

Сделал три вещи
  миграция логгера готова
  завтра дейли перенесли на 12
  еще думаю про кэш в checkout

(children are unrelated topics, not elaboration of the thesis - this is
three islands wearing one trench coat; a child must explain its parent:
mechanism, reason, example, or consequence)

## socratic spam

Что такое Raft? Зачем нужен лидер? Почему важны термы? Как происходит коммит?
  ...

(every thesis turned into a question - questions stop opening reasoning and
become wallpaper; use a question only where the reader would actually ask it)

## over-nesting

Деплой упал из-за миграции
  миграция добавляет индекс
    индекс строится конкурентно
      конкурентное построение требует отдельной транзакции
        а наш раннер заворачивает все в одну
          поэтому postgres отклонил команду

(depth 5+ is a staircase, not a thought - past level 3-4 split the island
or flatten siblings that do not truly nest)
