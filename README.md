# ChatGPT
This is a demo for OpenAI's ChatGPT preview. It uses the OpenAI ChatGPT backend API to communicate with the model.
Please remember that this is just a quick demo I put together. It may have bugs, work incorrectly, or stop working altogether e.g. if OpenAI decides to change anything. If you do find anything or have questions feel free to open a issue, or PR if you feel like fixing anything :)

# Important ⚠️
OpenAI added Cloudflare protection to it's website and API. Meaning this project currently doesn't work anymore.
If you find a fix or have ideas abou that feel free to open an PR or discussion.

## Use
In order to use make request you need to get a *session* token (jwt) or an access token from OpenAI and paste it in `OpenAI.swift`.
When a session token is provided it will automatically refresh the access token on start and when reseting the conversation.

## Fun Facts
Afaik ChatGPT's dataset goes up until April 2021, since it knows about M. Collins's death on the 28th. It claims that people who dies after that date are still alive.

## Helpful Links:
- [OpenAI ChatGPT](https://openai.com/blog/chatgpt/)
- [OpenAI ChatGPT Preview](https://chat.openai.com)
