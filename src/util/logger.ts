// const Reset = '\x1b[0m'
// const Bright = '\x1b[1m'
const Dim = "\x1b[2m"
// const Underscore = '\x1b[4m'
// const Blink = '\x1b[5m'
// const Reverse = '\x1b[7m'
// const Hidden = '\x1b[8m'

// const FgBlack = '\x1b[30m'
// const FgRed = '\x1b[31m'
const FgGreen = "\x1b[32m"
const FgYellow = "\x1b[33m"
// const FgBlue = '\x1b[34m'
// const FgMagenta = '\x1b[35m'
const FgCyan = "\x1b[36m"
const FgWhite = "\x1b[37m"

// const BgBlack = '\x1b[40m'
const BgRed = "\x1b[41m"
// const BgGreen = '\x1b[42m'
// const BgYellow = '\x1b[43m'
// const BgBlue = '\x1b[44m'
// const BgMagenta = '\x1b[45m'
// const BgCyan = '\x1b[46m'
// const BgWhite = '\x1b[47m'

const isBrowser = typeof window !== "undefined" && Reflect.has(window, "document")
const Clear = isBrowser ? "" : "\x1b[0m"

const Levels = {
  VERBOSE: "verbose",
  DEBUG: "debug",
  TRACE: "trace",
  INFO: "info",
  WARN: "warn",
  ERROR: "error",
} as const

type LogLevel = (typeof Levels)[keyof typeof Levels]

const Colors: Record<LogLevel, string> = {
  debug: `${Dim}${FgGreen}`,
  trace: `${Dim}${FgCyan}`,
  info: `${FgCyan}`,
  error: `${BgRed}${FgWhite}`,
  warn: `${FgYellow}`,
  verbose: `${FgWhite}`,
}

const prefix = `gcd`

/** Writes one prefixed, level-tagged line unless the browser environment is silenced. */
function log(level: LogLevel, ...params: unknown[]): null | void {
  if (isBrowser) return null // production and demo stay silent on the frontend

  console.log(
    `${isBrowser ? Colors[level] : ""}${prefix}::${String(level).toUpperCase()}\t`,
    `${isBrowser ? Clear : ""}`,
    ...params,
  )
}

const logger = {
  log(...params: unknown[]) {
    return log(Levels.VERBOSE, ...params)
  },
  debug(...params: unknown[]) {
    return log(Levels.DEBUG, ...params)
  },
  trace(...params: unknown[]) {
    return log(Levels.TRACE, ...params)
  },
  info(...params: unknown[]) {
    return log(Levels.INFO, ...params)
  },
  warn(...params: unknown[]) {
    return log(Levels.WARN, ...params)
  },
  error(...params: unknown[]) {
    return log(Levels.ERROR, ...params)
  },
}

export default logger
