import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { donorOnly } from "../middleware/roleMiddleware.js";
import {
    createFoodListing,
    getAllFoodListings,
    getNearbyFood,
} from "../controllers/foodController.js";

const router = express.Router();

router.get("/", getAllFoodListings);
router.get("/nearby", getNearbyFood);
router.post("/create", protect, donorOnly, createFoodListing);

export default router;