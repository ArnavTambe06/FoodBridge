import PickupRequest from "../models/PickupRequest.js";
import Food from "../models/Food.js";

/*
CREATE PICKUP REQUEST
POST /api/pickup/request
*/



export const createPickupRequest = async (req, res) => {
    try {

        const { foodId } = req.body;

        const ngoId = req.user._id;

        const food = await Food.findById(foodId);

        if (!food) {
            return res.status(404).json({
                error: "Food not found"
            });
        }

        if (food.status !== "available") {
            return res.status(400).json({
                error: "Food is already reserved or picked"
            });
        }

        const existingRequest = await PickupRequest.findOne({
            foodId,
            status: "pending"
        });

        if (existingRequest) {
            return res.status(400).json({
                error: "Pickup request already exists for this food"
            });
        }

        const pickup = new PickupRequest({
            foodId,
            ngoId,
            donorId: food.donorId
        });

        await pickup.save();

        // mark food as reserved
        food.status = "reserved";

        await food.save();

        res.status(201).json({
            message: "Pickup request created",
            pickup
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};
/*
GET ALL PICKUP REQUESTS
GET /api/pickup
*/
export const getAllPickupRequests = async (req, res) => {
    try {

        const pickups = await PickupRequest.find()
            .populate("foodId");

        res.status(200).json(pickups);

    } catch (error) {
        res.status(500).json({
            error: error.message
        });
    }
};



export const acceptPickupRequest = async (req, res) => {
    try {

        const pickup = await PickupRequest.findById(req.params.id);

        if (!pickup) {
            return res.status(404).json({
                error: "Pickup request not found"
            });
        }

        if (pickup.donorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                error: "Not authorized"
            });
        }

        pickup.status = "accepted";

        await pickup.save();

        res.json({
            message: "Pickup request accepted",
            pickup
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};


export const rejectPickupRequest = async (req, res) => {
    try {

        const pickup = await PickupRequest.findById(req.params.id);

        if (!pickup) {
            return res.status(404).json({
                error: "Pickup request not found"
            });
        }

        if (pickup.donorId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                error: "Not authorized"
            });
        }

        pickup.status = "rejected";

        await pickup.save();

        res.json({
            message: "Pickup request rejected",
            pickup
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};


export const completePickupRequest = async (req, res) => {
    try {

        const pickup = await PickupRequest.findById(req.params.id);

        if (!pickup) {
            return res.status(404).json({
                error: "Pickup request not found"
            });
        }

        pickup.status = "completed";

        await pickup.save();

        await Food.findByIdAndUpdate(
            pickup.foodId,
            { status: "picked" }
        );

        res.json({
            message: "Pickup completed"
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};