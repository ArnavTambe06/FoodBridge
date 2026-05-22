import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { ngoOnly } from "../middleware/roleMiddleware.js";
import {
    createPickupRequest,
    getAllPickupRequests
} from "../controllers/pickupController.js";

const router = express.Router();

router.post("/request", protect, ngoOnly, createPickupRequest);

router.get("/", getAllPickupRequests);

router.patch("/:id/accept", protect, donorOnly, acceptPickupRequest);

router.patch("/:id/reject", protect, donorOnly, rejectPickupRequest);

router.patch("/:id/complete", protect, donorOnly, completePickupRequest);

export default router;