import { AClassThatDoesStuff } from "./AClassThatDoesStuff"

export {}
declare global {
  interface Window {
    flutter_inappwebview: FlutterInAppWebView
    doSomeStuff: (aParam: string) => void
    aClassDoingStuff: AClassThatDoesStuff
  }
}

interface FlutterInAppWebView {
  callHandler(handlerName: string, ...args: any[]): Promise<any>
}
