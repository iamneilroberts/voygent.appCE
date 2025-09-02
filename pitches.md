For AI Enthusiasts, Devs, Vibe Coders, and Techy Travel Pros

Voygent is AI‑native by design—not a bolt‑on chatbot. Every workflow is broken into phases with LLM‑friendly schemas, so the model stays grounded and efficient.

Highlights:

AI at the core: From database schema (hybrid JSONB + normalized tables) to template rendering, everything is optimized for LLM reasoning.

Context‑aware prompts: Cloudflare Worker MCP streams small, focused instructions instead of giant static system prompts.

Browser automation: Use mcp‑chrome (or Opera Neon when ready) to extract live booking data. No brittle scraping hacks.

Composable stack: Dockerized LibreChat + Orchestrator + D1 MCP, with clear extensibility for other MCP servers.

Rapid iteration: Early adopters can fork templates, add MCPs, and experiment with AI‑first flows.

Benefits:

Slash planning time from hours → minutes

Save costs by mixing smaller models (Claude Haiku, GPT‑mini) for high‑volume tasks

Unlock new commission streams with upsell suggestions

Experiment with a real AI‑first SaaS‑like travel platform locally

For Travel Agents (Early Adopters)

If you’re a travel professional tired of clunky tools, Voygent CE gives you an AI‑first Travefy beater:

Pain point solved: No more copy/paste into dated editors. Voygent builds sleek proposals directly from your intake.

Dashboard clarity: See all trips, proposals, validation reports, and commission status in one place.

Inventive itineraries: LLM creates themed trip concepts tailored to your clients—city culture, foodie adventures, hiking escapes.

Free extras: Dining suggestions, maps, activities, and day‑by‑day flows enrich your proposals at no cost.

Commission maximizer: Built‑in analysis shows you how to hit 15–18% margins by switching vendors, adding service fees, or upselling.

Cost/time savings: Replace hours of manual work with a few guided prompts. A single extra commission win can pay for your setup.

Compared to alternatives: Travefy is manual and slow. Voygent is automated, modern, and AI‑first.

Elevator Pitch (Investors & Fellow AI Builders)

Voygent is the killer AI travel app: a practical, revenue‑driving assistant for agents and agencies.

Problem: Travel agents waste hours on proposals, often with thin commissions and outdated tools.

Solution: Voygent automates intake → proposal → validation → commissions, delivering bookable trips with modern UX.

Moat: AI‑native architecture (schemas, MCP orchestration, templates) makes Voygent uniquely extensible and efficient.

Market: $200B+ global leisure travel booked via agents, with growing demand for AI productivity tools.

Why now: AI models are ready, browser automation tools (Neon, MCP‑Chrome) are emerging, and agents are eager for differentiation.

Tagline: Voygent—AI that sells the sizzle and secures the sale.

Features (Phase 1 – CE)

AI‑assisted itineraries: From lead intake to trip concepts to final proposal.

Beautiful proposals: Render HTML → PDF with modern templates.

Self‑hosted dashboard: Manage clients, trips, and proposals.

Bring Your Own AI Key: Works with Claude, GPT, Gemini, etc.

Local browser integration: Use mcp‑chrome (or Opera Neon when available) for live extraction from booking sites.

Open database schema: Hybrid normalized + LLM‑friendly tables.

Architecture Overview

LibreChat inside Docker – orchestrator + UI.

Cloudflare D1 (default) or Postgres/Neon – trip & proposal data.

Nunjucks/Handlebars templates – render HTML proposals.

Caddy reverse proxy with HTTPS.

MCP servers:

mcp-chrome (local install, outside Docker)

Cloudflare Workers MCP (prompt-instructions)

Other MCPs as needed (e.g. HTML ingestion, custom APIs)

❗ mcp‑chrome should run separately on the user’s local machine for browser integration. Running it in Docker is possible but brittle.