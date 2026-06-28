# TerritoryX — Digital Billboard Real Estate Platform

> Own The Map. Own The Attention.

A real-time digital billboard territory ownership platform for Southern African markets (Eswatini, South Africa, Botswana).

---

## Files

| File | Purpose |
|---|---|
| `index.html` | **Frontend** — Customer-facing billboard display. Connect to Supabase to load live data. |
| `tx_admin.html` | **Admin Panel** — Full CRUD management for nodes, bids, config, categories, ticker. |
| `tx_schema.sql` | **Database Schema** — Run this in Supabase SQL Editor to set up all tables + seed data. |

---

## Quick Start

### 1. Set up Supabase
- Create a project at [supabase.com](https://supabase.com)
- Go to **SQL Editor → New Query**
- Paste contents of `tx_schema.sql` and run

### 2. Open the Frontend
- Open `index.html` in browser
- Enter your **Supabase Project URL** + **Anon Key**
- Keys are saved locally — one-time setup

### 3. Open the Admin Panel
- Open `tx_admin.html` in browser
- Enter Project URL + **Anon Key** + **Service Role Key** + Admin password
- Default admin password: `txadmin2025` (change in Platform Config after first login)

---

## Admin Panel Features

- **Nodes** — Add/edit/delete billboard territories (name, location, value, owner, lat/lng, image)
- **Bids** — View and manage all override requests from the frontend
- **Platform Config** — WhatsApp number, currency, increment rules, display settings — all without code changes
- **Categories** — Add new node types (Urban Hub, Airport Hub, Stadium Hub, etc.)
- **Challengers** — Manage contesting brands per node
- **Ticker Messages** — Edit the live scrolling feed
- **Prestige Tiers** — Customize badge colors and value thresholds

---

## Tech Stack

- **Frontend**: Vanilla HTML/CSS/JS — single file, no build step
- **Backend**: [Supabase](https://supabase.com) (Postgres + RLS + REST API)
- **Auth**: Supabase anon key (public read) + service role key (admin write)
- **Bids**: Saved to Supabase `tx_bids` table + routed to WhatsApp

---

Built for Southern African markets 🇸🇿🇿🇦🇧🇼

