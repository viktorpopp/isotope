---
title: Isotope Specification
---

The Isotope specification is a set of APIs for federated communication. Its goal is to define a secure and private way
of communicating online. It is highly inspired by [Matrix](https://spec.matrix.org/), but with an interface that is
similar to other popular messaging platforms, such as [Slack](https://slack.com/) and [Discord](https://discord.com/).

## Introduction

The principles that guide the design of Isotope are:

- Keep it fully open:
  - Fully open federation: Anyone should be able to participate in the Isotope network.
  - Fully open standard: Publicly documented standard with no IP or proprietary lock-in.
- Learning from previous protocols whilst trying to avoid their failings.

### Requirement Levels

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
[RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Architecture

<!-- Describe, simply, how the architecture works. -->

### Users

Each user has an unique identifier, their "User ID", which is a string namespaced to the users
[homeserver](#homeservers). It has the following format:

```
@<localpart>:<domain>
```

### Clients

A client application is a program that a [user](#users) interacts with the network, e.g. a desktop application, a mobile
app, or a web client. Each client can have multiple [users](#users) logged in simultaneously.

### Homeservers

A homeserver is a node in the network. It is responsible for hosting things like [users](#users) and [spaces](#spaces).

### Space

A space is a collection of [channels](#channels) that are organized together. It can be compared to a
[Slack](https://slack.com/) workspace or a [Discord](https://discord.com/) server. A space is typically recognized by a
subdomain under the [homeserver](#homeservers) domain, e.g. `space.example.com` (This is similar to how
[Slack](https://slack.com/) manages workspaces).

### Channels

A channel the place where the messages themselves are sent. It can be compared to a [Slack](https://slack.com/)'s and
[Discord](https://discord.com/)'s channels.
