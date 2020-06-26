SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: alen_marz
--
DROP SCHEMA IF EXISTS lens cascade ;
CREATE SCHEMA lens;
SET search_path = lens;

CREATE TABLE category_types (
    id SERIAL PRIMARY KEY ,
    name character varying unique
);
COMMENT ON TABLE category_types IS 'Типы категорий товара: например материал, тип линзы';

CREATE TABLE categories (
    id SERIAL PRIMARY KEY ,
    category_id INTEGER REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE CASCADE ,
    type_id integer REFERENCES category_types (id) ON DELETE RESTRICT ON UPDATE CASCADE ,
    name character varying NOT NULL UNIQUE ,
    description text,
    created_at timestamp without time zone NOT NULL DEFAULT current_timestamp ,
    updated_at timestamp without time zone
);
COMMENT ON TABLE categories IS 'Категории товара';
COMMENT ON COLUMN categories.category_id IS 'Родительская категория (например: Линзы является родительской для гидрогелевые)';
COMMENT ON COLUMN categories.type_id IS 'тип категоризации, например материал, тип линзы';
COMMENT ON COLUMN categories.updated_at IS 'Поле для использования кэширования, триггером обновляется при любом изменении категории или товара в ней'
COMMENT ON COLUMN categories.description IS 'поле с html блоком описания категории';

CREATE TABLE products(
    id serial primary key,
    name character varying not null unique,
    description character varying,
    status integer default 0 not null,
    created_at timestamp without time zone NOT NULL DEFAULT current_timestamp,
    specification jsonb not null default '{}'::jsonb,
    price numeric not null
);
COMMENT ON TABLE products IS 'Товар';
COMMENT ON COLUMN products.name IS 'Наименование';
COMMENT ON COLUMN products.status IS 'Статус по умолчанию 0 - на модерации (не видим пользователю) дальше по желанию';
COMMENT ON COLUMN products.specification IS 'Набор характеристик - json например {"Диаметр": 14.3, "Толщина в центре":0.085}';

CREATE TABLE product_category (
    product_id integer references products (id) ON DELETE cascade ON UPDATE cascade ,
    category_id integer references categories (id) on delete cascade ON update cascade,
    primary key (product_id, category_id)
);

COMMENT ON TABLE product_category IS 'Привязка товара к категориям один товар может быть в нескольких категориях';

CREATE TABLE options (
    id SERIAL PRIMARY KEY ,
    name character varying NOT NULL
);
COMMENT ON TABLE options IS 'Набор Характеристик товара, которые можно выбрать: Например Базовая кривизна';


CREATE TABLE option_values (
    id SERIAL PRIMARY KEY ,
    option_id INTEGER references options(id) on delete cascade on update cascade NOT NULL ,
    value character varying NOT NULL
);
COMMENT ON TABLE option_values IS 'значения для набора Характеристик товара, которые можно выбрать: Например 0.25';

CREATE TABLE product_options (
    option_id integer references options(id) NOT NULL,
    product_id integer references products(id) NOT NULL,
    primary key (option_id, product_id)
);
COMMENT ON TABLE product_options IS 'Связь продукта с его возможной вариацией';

CREATE TABLE variants (
    id bigserial primary key,
    product_id integer references products(id) NOT NULL,
    price numeric NOT NULL,
    quantity integer not null
);
COMMENT ON TABLE variants IS 'Вариант продукта выбранный покупателем';
COMMENT ON COLUMN variants.price IS 'Цена отдельно, для того чтобы изменение цены продукта не влияло на цену в заказе';
COMMENT ON COLUMN variants.quantity IS 'количество товара';

CREATE TABLE variant_option_values (
    variant_id bigint references variants (id) not null ,
    option_value_id bigint references option_values(id) NOT NULL,
    primary key (variant_id, option_value_id)
);
comment on table variant_option_values is 'Для выбранного варианта набор выбранных характеристик';


CREATE TABLE customers (
    id serial primary key ,
    first_name character varying ,
    last_name character varying ,
    phone character varying NOT NULL,
    email character varying,
    created_at timestamp without time zone NOT NULL DEFAULT current_timestamp
);
COMMENT ON TABLE customers IS 'Покупатели';


CREATE TABLE orders (
    id BIGSERIAL primary key ,
    status integer DEFAULT 0 NOT NULL,
    customer_id integer references customers(id) on delete restrict on update cascade NOT NULL,
    created_at timestamp without time zone NOT NULL default current_timestamp,
    updated_at timestamp without time zone NOT NULL
);
COMMENT ON TABLE orders IS 'заказы';

CREATE TABLE order_positions (
    order_id bigint references orders (id) NOT NULL,
    variant_id bigint references variants(id) NOT NULL
);
COMMENT ON TABLE order_positions IS 'позиции заказа';

create table users
(
	id serial not null primary key,
	login character varying not null,
	pass character varying not null,
	salt character varying,
	status bigint default 1,
	created_at timestamp default current_timestamp::timestamp without time zone
);
COMMENT ON table users IS 'Администраторы сайта';
COMMENT ON COLUMN users.pass IS 'Хэш пароля';
COMMENT ON COLUMN users.salt is 'Соль';
COMMENT ON COLUMN users.status is 'СТатус 1 - действует, остальные по усмотрению';

CREATE TABLE rbac_roles(
    id serial primary key ,
    name character varying unique
);
COMMENT ON TABLE rbac_roles IS 'Роли';

CREATE TABLE user_assignment(
    user_id integer references users(id) not null,
    role character varying references rbac_roles(name) not null,
    primary key (user_id, role)
);
COMMENT ON TABLE user_assignment IS 'привязка ролей пользователям';

CREATE TABLE articles (
    id serial primary key ,
    picture character varying,
    title character varying,
    body character varying,
    status integer default 0 not null,
    created_by integer references users(id) not null ,
    created_at timestamp not null default current_timestamp
);
comment on table articles is 'статьи';
comment on column articles.status is 'статус 0 - на модерации (не тображать пользователю)';

CREATE TABLE feedbacks (
    id bigserial primary key ,
    product_id integer references products (id) not null,
    rating integer not null default 5,
    user_name character varying not null,
    user_mail character varying not null ,
    body character varying not null,
    created_at timestamp not null default current_timestamp
);
comment on table feedbacks is 'отзывы';
comment on column feedbacks.rating is 'рэйтинг от 0 до 5';

CREATE TABLE feedback_comments (
    id bigserial primary key ,
    feedback_id bigint references feedbacks (id) not null ,
    user_id integer references users(id) not null,
    body character varying not null ,
    created_at timestamp not null default current_timestamp
);
comment on table feedback_comments is 'комментарий к отзыву';
