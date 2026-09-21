# What This Project Actually Is (No Jargon)

## The Problem

At most companies, when a developer wants to build a new piece of
software, they have to do a lot of setup work first: create a place to
store the code, set up automated testing, figure out how to get it
running on real servers, set up monitoring so someone knows if it
breaks, and make sure none of it can be tampered with. That setup work
is repetitive, easy to get wrong, and takes time away from actually
building the product.

## What This Project Builds

This project builds a small version of what's called an "internal
developer platform" — a system that handles all of that repetitive
setup automatically, so a developer can focus on writing their
application instead of configuring infrastructure around it.

## How It Works, In Plain Terms

1. **A developer writes code and saves it (a "commit").**
2. **An automated pipeline picks it up**, runs tests on it, scans it for
   known security issues, and — if everything passes — packages it into
   a container image (think of this like a shipping container for
   software: it runs the same way no matter what machine it's placed
   on).
3. **That image is stored** in a private, access-controlled registry.
4. **A separate system continuously watches** a record of "what should
   be running" (stored in Git, the same tool used to track code
   changes) and automatically updates the live servers to match it. If
   someone manually changes something on the live servers without going
   through this process, the system notices and reverts it back to
   match the record — automatically.
5. **New versions are rolled out gradually**, not all at once. A new
   version first gets a small slice of traffic, gets automatically
   checked for problems, and only gets the rest of the traffic if it
   passes. If it doesn't pass, the system automatically pulls it back
   and the previous, working version keeps running the whole time.
6. **Rules are enforced automatically.** For example, this project
   blocks anyone — including the platform's own creator — from
   deploying a container image that isn't properly version-tagged,
   because an untagged image is a real, historically common cause of
   "it worked yesterday and I don't know why it broke today."
7. **The system watches its own health** and can report which parts of
   itself are actually running correctly, and roughly what each part
   costs to run.

## What Makes This Different From Just "Using Kubernetes"

Kubernetes (the underlying system that actually runs the software) is
only one piece. On its own, Kubernetes doesn't know about testing,
security scanning, gradual rollouts, or automatic rule enforcement —
those are all things layered on top, and building that layer correctly
is most of what this project actually is.

## What This Project Does Not Claim

This is a demonstration platform, not a production system serving real
users. It runs on a small amount of infrastructure, some pieces (like
chat alerts when something breaks) were built but never fully
confirmed working, and one intended feature (letting a developer
publish a brand-new service directly from the portal) isn't finished
yet. These limitations are documented on purpose, in
`docs/engineering/technical-debt.md` — a system that claims to have no
limitations is usually one that hasn't been looked at closely enough.
