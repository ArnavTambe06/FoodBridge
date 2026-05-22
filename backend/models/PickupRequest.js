import mongoose from "mongoose";

const pickupRequestSchema = new mongoose.Schema(
    {
        foodId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Food",
            required: true
        },

        ngoId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        donorId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        status: {
            type: String,
            enum: ["pending", "accepted", "rejected", "completed"],
            default: "pending"
        }

    },
    { timestamps: true }
);

const PickupRequest = mongoose.model("PickupRequest", pickupRequestSchema);

export default PickupRequest;