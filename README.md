## Rails Case – Product Management and Google Sheets Synchronization

This project is a sample application built with **Ruby on Rails** that performs **product management (CRUD)** and provides **two-way synchronization with Google Sheets**.  

### Features

- **Product CRUD**:
  - List products, view details, create, update, delete
  - Fields: **name, price, stock, category, uuid, external_id**
- **Google Sheets integration**:
  - **Sheet → DB (Sync from Google Sheet)**  
    Reads products from rows in a Google Sheet, saves/updates them in the database, and deletes records from the DB that do not exist in the Sheet.
  - **DB → Sheet (Sync to Google Sheet)**  
    Writes all products from the database to the Sheet, fixes the header, and clears old rows.
  - For invalid rows, writes validation errors into the **Error** column in the Sheet.
- **UUID-based synchronization**:
  

## Technologies and Dependencies

- **Language / Framework**
  - Ruby `3.4.7`
  - Rails `~> 8.1.1`
- **Database**
  - PostgreSQL
- **Frontend**
  - `bootstrap`
  - `jsbundling-rails`
  - `cssbundling-rails`
- **Google Sheets integration**
  - `google-apis-sheets_v4`
  - `googleauth`
  - Authentication with a Service Account (`config/service_account.json`)

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/gzcmustafa/rails-case.git
cd rails-case
```

Replace `<repo-url>` with your own GitHub repository URL.

### 2. Dependencies 

For backend dependencies:

```bash
gem install bundler
bundle install
```

For frontend dependencies:

```bash
npm install
# or
yarn install
```

> Note: Since the project includes `package.json` and `yarn.lock`, using `yarn` is recommended.

### 4. Database Settings

PostgreSQL settings are located in `config/database.yml`.  
After configuring the appropriate username/password in your local environment:

```bash
bin/rails db:prepare
# or
bin/rails db:create db:migrate
```

---

## Google Sheets Integration

Two things are required for the Sheets integration:

- **Service Account JSON file**
- **Google Sheet ID (GOOGLE_SHEET_ID environment variable)**

### 1. Google Cloud and Service Account

- Create a **Service Account** in Google Cloud Console.
- Enable the **Google Sheets API**.
- Generate a **JSON key** for the service account.
- Place this JSON file in the project at `config/service_account.json`.

> Note: This file is usually kept in `.gitignore` for security reasons.

### 2. Preparing the Google Sheet

- Create a new Google Sheet in Google Drive.
- Define at least the following header row starting from A1:

```text
UUID | Name | Price | Stock | Category | Error
```

- Get the **ID** of the Sheet (the long ID in the URL).
- **Share** the Sheet with the service account email address.

### 3. Environment Variable (GOOGLE_SHEET_ID)

You can use a `.env` file in your local development environment.

```env
GOOGLE_SHEET_ID=your_sheet_id_here
```

---

## Running the Application

### 1. In development (bin/dev)

In accordance with the Rails 8 standard:

```bash
bin/dev
```

This command starts both the Rails server and the frontend build processes (JS/CSS) at the same time.  
By default, the application runs at `http://localhost:3000`.

### 2. Alternative (Rails server only)

```bash
bin/rails server
```

In this case, you may need to manually run commands such as `yarn build --watch` for JS/CSS.

---












