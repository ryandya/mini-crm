# Mini-CRM: объекты и задачи

## Настройка Supabase

1. Создайте проект Supabase и примените миграции из `supabase/migrations/` по порядку.
2. Отключите открытую регистрацию в настройках Supabase Auth. Пользователей создавайте только вручную через Supabase Dashboard (или приглашением администратора).
3. Для каждого пользователя скопируйте UUID из Authentication → Users и добавьте строку в `public.profiles` с одной ролью: `manager` или `executor`. Роль назначается доверенным администратором, клиент не может её менять.
4. Для демо откройте `supabase/seed.sql`, замените UUID шаблоны существующими UUID пользователей Auth: manager — `00000000-0000-4000-8000-000000000001`, executor — `00000000-0000-4000-8000-000000000002`. Выполните файл целиком в SQL Editor. Seed создаёт задачи от менеджера и использует `change_task_status` для получения задач в пяти статусах.

В SQL Editor `auth.uid()` обычно равен `null`; seed устанавливает `request.jwt.claims` через `set_config` в той же транзакции перед каждым действием от имени менеджера или исполнителя. Профили добавляются напрямую, объекты — с явным `created_by`.

## Локальная разработка

Скопируйте `.env.example` в `.env.local` и укажите URL проекта и публичный publishable/anon ключ:

```dotenv
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY
```

`service_role` и другие секретные ключи нельзя помещать во frontend env или коммитить. Файлы `.env*` игнорируются Git.

```bash
npm install
npm run dev
```

## Структура исходников

`src/` организован по FSD: `app`, `pages`, `widgets`, `features`, `entities`, `shared`. Импорты идут сверху вниз, публичный API каждого модуля экспортируется через `index.ts`.
