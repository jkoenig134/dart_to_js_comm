import { randomDogName } from "dog-names"
import { AClassThatDoesStuff } from "./AClassThatDoesStuff"

console.log("Hello from index.ts")

window.aClassDoingStuff = new AClassThatDoesStuff()

window.doSomeStuff = async (aParam: string) => {
  console.log(aParam)
  const file = await window.flutter_inappwebview.callHandler("pickFile")

  if (file == null) {
    console.log("No file selected")
    return
  }

  console.log("file", file)

  const fileContent = await window.flutter_inappwebview.callHandler("readFile", file)
  console.log("fileContent", fileContent)
}

let index = 0
setInterval(async () => {
  await window.flutter_inappwebview.callHandler("handleEvent", "aNamespace", {
    index: index++,
    dogName: randomDogName(),
  })
}, 1000)
