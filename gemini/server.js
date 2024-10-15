const PORT = 8000
const express = require('express')
const cors = require('cors')
const fs = require('fs')
const multer = require('multer')
require('dotenv').config()
const {GoogleGenerativeAI} = require("@google/generative-ai")

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY)

const app = express()
app.use(cors())
app.use(express.json())


const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public')
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + "-" + file.originalname)
    }
})

const upload = multer({ storage: storage}).single('file')

function decodeBase64Image(base64Image) {
    const buffer = Buffer.from(base64Image, 'base64');
    return buffer;
}

let filePath

app.post('/upload', (req, res) => {

  try{  
    // upload(req, res, (err) => {
    //     if(err) {
    //         return res.send(500).json(err)
    //     }
    //     filePath = file.path
    // })
    filePath = 'public/' + 'image-'+ Date.now() + '.jpeg'
    const file = decodeBase64Image(req.body.file);
    fs.writeFileSync(filePath, file);
    res.statusCode = 200;
    res.send();
} catch(err) {
        console.error(err)
    }
})

app.post('/gemini', async (req, res) => {
    try{
        console.log(req);
        function fileToGenerativePart(path, mimeType) {
            return {
                inlineData: {
                    data: Buffer.from(fs.readFileSync(path)).toString("base64"),
                    mimeType: mimeType
                }
            }
        }

        const model = genAI.getGenerativeModel({model: "gemini-1.5-flash-latest"})
        const prompt = req.body.text
        console.log(prompt)
        const result = await model.generateContent([prompt, fileToGenerativePart(filePath, "image/jpeg")])
        const response = result.response
        const text = response.text()
        console.log(text)
        res.send(text)

    } catch(err) {
        console.error(err)
    }
})




app.listen(PORT, () => console.log("Listening on port 8000"))
