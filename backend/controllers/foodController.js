import Food from "../models/Food.js";
import User from "../models/User.js";

/*
CREATE FOOD LISTING
POST /api/food/create
*/
export const createFoodListing = async (req, res) => {
    try {

        const { foodName, quantity, description, lat, lng, donorId } = req.body;

        const user = await User.findById(donorId);

        if (!user) {
            return res.status(404).json({
                error: "User not found"
            });
        }

        if (user.role !== "donor") {
            return res.status(403).json({
                error: "Only donors can post food"
            });
        }

        const food = new Food({
            foodName,
            quantity,
            description,

            location: {
                type: "Point",
                coordinates: [lng, lat]
            },

            donorId: req.user._id
        });

        await food.save();

        res.status(201).json({
            message: "Food listing created",
            food
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};


/*
GET ALL FOOD LISTINGS
GET /api/food
*/
export const getAllFoodListings = async (req, res) => {
    try {

        const foods = await Food.find();

        res.status(200).json(foods);

    } catch (error) {
        res.status(500).json({
            error: error.message
        });
    }
};


/*
GET NEARBY FOOD
GET /api/food/nearby?lat=...&lng=...
*/
export const getNearbyFood = async (req, res) => {
    try {

        const { lat, lng } = req.query;

        const foods = await Food.find({
            location: {
                $near: {
                    $geometry: {
                        type: "Point",
                        coordinates: [lng, lat]
                    },
                    $maxDistance: 5000 // 5km radius
                }
            },
            status: "available"
        });

        res.status(200).json(foods);

    } catch (error) {
        res.status(500).json({
            error: error.message
        });
    }
};