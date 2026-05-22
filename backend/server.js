//import { db } from "./config/firebase.js";
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import connectDB from "./config/db.js";

//routes imports
import authRoutes from "./routes/authRoutes.js";
import foodRoutes from "./routes/foodRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import pickupRoutes from "./routes/pickupRoutes.js";


connectDB();

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Test Route
app.get("/", (req, res) => {
    res.send("FoodBridge API Running 🚀");
});

// Health Check Route
app.get("/api/health", (req, res) => {
    res.status(200).json({
        status: "OK",
        message: "FoodBridge backend is running"
    });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/food", foodRoutes);
app.use("/api/users", userRoutes);
app.use("/api/pickup", pickupRoutes);


const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});



//testRoute
// app.get("/api/test-db", async (req, res) => {
//     try {
//         const docRef = db.collection("test").doc("connection");

//         await docRef.set({
//             status: "connected",
//             timestamp: new Date()
//         });

//         res.json({
//             message: "Firestore connection successful"
//         });

//     } catch (error) {
//         res.status(500).json({
//             error: error.message
//         });
//     }
// });