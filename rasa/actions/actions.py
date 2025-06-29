from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet
import requests
import json
import logging
import psycopg2
from psycopg2.extras import RealDictCursor
import os

logger = logging.getLogger(__name__)

# Database connection helper
def get_db_connection():
    return psycopg2.connect(
        host=os.getenv('POSTGRES_HOST', 'postgres'),
        database=os.getenv('POSTGRES_DB', 'ev_charger_chatbot_db'),
        user=os.getenv('POSTGRES_USER', 'ev_chatbot_user'),
        password=os.getenv('POSTGRES_PASSWORD', 'ev_secure_password_123')
    )

class ActionSetLanguage(Action):
    def name(self) -> Text:
        return "action_set_language"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        language = tracker.get_slot("selected_language")
        
        if language == "english":
            dispatcher.utter_message(response="utter_greet_english")
            dispatcher.utter_message(response="utter_services_english")
        elif language == "french":
            dispatcher.utter_message(response="utter_greet_french")
            dispatcher.utter_message(response="utter_services_french")
        elif language == "arabic":
            dispatcher.utter_message(response="utter_greet_arabic")
            dispatcher.utter_message(response="utter_services_arabic")
        elif language == "darija":
            dispatcher.utter_message(response="utter_greet_darija")
            dispatcher.utter_message(response="utter_services_darija")
        
        return [SlotSet("selected_language", language)]

class ActionSuggestChargers(Action):
    def name(self) -> Text:
        return "action_suggest_chargers"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        installation_type = tracker.get_slot("installation_type") or "residential"
        charger_type = tracker.get_slot("charger_type")
        language = tracker.get_slot("selected_language") or "english"
        
        # Get charger suggestions from database
        chargers = self.get_charger_suggestions(installation_type, charger_type)
        
        if language == "english":
            if chargers:
                message = f"Here are my top EV charger recommendations for {installation_type} use:\n\n"
                for i, charger in enumerate(chargers[:3], 1):
                    message += f"🔌 **{charger['name']}**\n"
                    message += f"   Power: {charger['power_output']}\n"
                    message += f"   Price: ${charger['price']}\n"
                    if charger['installation_cost'] > 0:
                        message += f"   Installation: ${charger['installation_cost']}\n"
                    message += f"   {charger['description']}\n\n"
                message += "Would you like more details about any of these chargers or an installation estimate?"
            else:
                message = "I couldn't find suitable chargers for your requirements. Let me connect you with our specialist."
                
        elif language == "french":
            if chargers:
                message = f"Voici mes meilleures recommandations de chargeurs EV pour usage {installation_type}:\n\n"
                for i, charger in enumerate(chargers[:3], 1):
                    message += f"🔌 **{charger['name']}**\n"
                    message += f"   Puissance: {charger['power_output']}\n"
                    message += f"   Prix: {charger['price']}€\n"
                    if charger['installation_cost'] > 0:
                        message += f"   Installation: {charger['installation_cost']}€\n"
                    message += f"   {charger['description']}\n\n"
                message += "Voulez-vous plus de détails sur l'un de ces chargeurs ou une estimation d'installation?"
            else:
                message = "Je n'ai pas trouvé de chargeurs adaptés à vos exigences. Laissez-moi vous connecter avec notre spécialiste."

        elif language == "arabic":
            if chargers:
                message = f"إليك أفضل توصياتي لشاحن المركبات الكهربائية للاستخدام {installation_type}:\n\n"
                for i, charger in enumerate(chargers[:3], 1):
                    message += f"🔌 **{charger['name']}**\n"
                    message += f"   القوة: {charger['power_output']}\n"
                    message += f"   السعر: {charger['price']} ريال\n"
                    if charger['installation_cost'] > 0:
                        message += f"   التركيب: {charger['installation_cost']} ريال\n"
                    message += f"   {charger['description']}\n\n"
                message += "هل تريد تفاصيل أكثر عن أي من هذه الشواحن أو تقدير للتركيب؟"
            else:
                message = "لم أجد شواحن مناسبة لمتطلباتك. دعني أربطك بمتخصصنا."

        elif language == "darija":
            if chargers:
                message = f"هاد هوما أحسن الشاحنات ديال الطوموبيلات الكهربائية لـ {installation_type}:\n\n"
                for i, charger in enumerate(chargers[:3], 1):
                    message += f"🔌 **{charger['name']}**\n"
                    message += f"   القوة: {charger['power_output']}\n"
                    message += f"   الثمن: {charger['price']} درهم\n"
                    if charger['installation_cost'] > 0:
                        message += f"   التركيب: {charger['installation_cost']} درهم\n"
                    message += f"   {charger['description']}\n\n"
                message += "بغيتي تفاصيل كتر على شي شاحن ولا تقدير للتركيب؟"
            else:
                message = "ما لقيتش شاحنات مناسبة لحاجتك. خليني نربطك مع المتخصص ديالنا."
        
        dispatcher.utter_message(text=message)
        return []

    def get_charger_suggestions(self, installation_type: str, charger_type: str = None) -> List[Dict]:
        try:
            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    if charger_type:
                        cur.execute("""
                            SELECT * FROM ev_chargers 
                            WHERE suitable_for = %s AND category = %s AND active = true 
                            ORDER BY price ASC LIMIT 5
                        """, (installation_type, charger_type))
                    else:
                        cur.execute("""
                            SELECT * FROM ev_chargers 
                            WHERE suitable_for = %s AND active = true 
                            ORDER BY price ASC LIMIT 5
                        """, (installation_type,))
                    
                    return [dict(row) for row in cur.fetchall()]
        except Exception as e:
            logger.error(f"Database error: {e}")
            return []

class ActionSuggestEVs(Action):
    def name(self) -> Text:
        return "action_suggest_evs"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        ev_make = tracker.get_slot("ev_make")
        language = tracker.get_slot("selected_language") or "english"
        
        # Get EV suggestions from database
        evs = self.get_ev_suggestions(ev_make)
        
        if language == "english":
            if evs:
                message = "Here are some excellent electric vehicles I recommend:\n\n"
                for ev in evs[:3]:
                    message += f"🚗 **{ev['make']} {ev['model']}**\n"
                    message += f"   Range: {ev['range_km']}km\n"
                    message += f"   Battery: {ev['battery_capacity']}\n"
                    message += f"   Fast Charging: {ev['max_charging_speed']}\n"
                    message += f"   Price: ${ev['price']:,.0f}\n\n"
                message += "Would you like to know about compatible chargers for any of these vehicles?"
            else:
                message = "Let me show you some popular electric vehicles and their charging requirements."
                
        # Add other languages...
        
        dispatcher.utter_message(text=message)
        return []

    def get_ev_suggestions(self, make: str = None) -> List[Dict]:
        try:
            with get_db_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    if make:
                        cur.execute("""
                            SELECT * FROM ev_vehicles 
                            WHERE make ILIKE %s AND active = true 
                            ORDER BY price ASC LIMIT 5
                        """, (f"%{make}%",))
                    else:
                        cur.execute("""
                            SELECT * FROM ev_vehicles 
                            WHERE active = true 
                            ORDER BY range_km DESC LIMIT 5
                        """, ())
                    
                    return [dict(row) for row in cur.fetchall()]
        except Exception as e:
            logger.error(f"Database error: {e}")
            return []

class ActionRequestEstimate(Action):
    def name(self) -> Text:
        return "action_request_estimate"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        # Collect customer data
        customer_data = {
            "name": tracker.get_slot("customer_name"),
            "email": tracker.get_slot("customer_email"),
            "phone": tracker.get_slot("customer_phone"),
            "company": tracker.get_slot("customer_company"),
            "installation_type": tracker.get_slot("installation_type"),
            "charger_type": tracker.get_slot("charger_type"),
            "ev_make": tracker.get_slot("ev_make"),
            "ev_model": tracker.get_slot("ev_model"),
            "language": tracker.get_slot("selected_language"),
            "conversation_id": tracker.sender_id
        }
        
        # Send data to n8n workflow for estimate calculation
        try:
            response = self.send_to_n8n_workflow(customer_data)
            
            language = tracker.get_slot("selected_language") or "english"
            
            if response and "estimate" in response:
                if language == "english":
                    message = f"Based on your requirements, here's your estimate:\n\n"
                    message += f"💰 **Total Estimate: ${response['estimate']['total_amount']}**\n"
                    if 'charger_cost' in response['estimate']:
                        message += f"🔌 Charger: ${response['estimate']['charger_cost']}\n"
                    if 'installation_cost' in response['estimate']:
                        message += f"🔧 Installation: ${response['estimate']['installation_cost']}\n"
                    message += f"\nThis estimate is valid for 30 days. Would you like to speak with our sales team to discuss financing options and schedule an installation?"
                else:
                    message = f"Based on your requirements, the estimated cost is ${response['estimate']['total_amount']}. Let me connect you with our sales team."
            else:
                message = "I'm having trouble calculating the estimate right now. Let me connect you with our sales team who can provide a detailed quote."
                
        except Exception as e:
            logger.error(f"Error calling n8n workflow: {e}")
            message = "I'm having trouble calculating the estimate right now. Let me connect you with our sales team who can help you directly."
        
        dispatcher.utter_message(text=message)
        return []

    def send_to_n8n_workflow(self, data: Dict) -> Dict:
        n8n_webhook_url = f"{os.getenv('N8N_WEBHOOK_BASE_URL', 'http://n8n:5678')}/webhook/ev-estimate-calculation"
        
        try:
            response = requests.post(
                n8n_webhook_url,
                json=data,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Error sending data to n8n: {e}")
            return {}

class ActionTransferToHuman(Action):
    def name(self) -> Text:
        return "action_transfer_to_human"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        language = tracker.get_slot("selected_language") or "english"
        
        # Collect all customer information
        customer_data = {
            "name": tracker.get_slot("customer_name"),
            "email": tracker.get_slot("customer_email"),
            "phone": tracker.get_slot("customer_phone"),
            "company": tracker.get_slot("customer_company"),
            "installation_type": tracker.get_slot("installation_type"),
            "charger_type": tracker.get_slot("charger_type"),
            "ev_make": tracker.get_slot("ev_make"),
            "ev_model": tracker.get_slot("ev_model"),
            "language": language,
            "conversation_id": tracker.sender_id
        }
        
        # Send handover request to n8n
        try:
            self.send_handover_request(customer_data)
            
            if language == "english":
                message = "Perfect! I'm connecting you with one of our EV charging specialists. They will contact you shortly to discuss your specific needs and provide a customized solution. Thank you for choosing EV Charge Solutions!"
            elif language == "french":
                message = "Parfait! Je vous connecte avec l'un de nos spécialistes en recharge EV. Ils vous contacteront bientôt pour discuter de vos besoins spécifiques. Merci d'avoir choisi EV Charge Solutions!"
            elif language == "arabic":
                message = "ممتاز! أقوم بربطك مع أحد متخصصي شحن المركبات الكهربائية لدينا. سوف يتصلون بك قريباً لمناقشة احتياجاتك المحددة. شكراً لاختيارك EV Charge Solutions!"
            elif language == "darija":
                message = "ممتاز! كانربطك مع واحد من متخصصي الشحن ديال الطوموبيلات الكهربائية ديالنا. غايتصلو بيك قريب باش نناقشو حاجاتك. شكراً لاختيارك EV Charge Solutions!"
                
        except Exception as e:
            logger.error(f"Error sending handover request: {e}")
            message = "I'm having trouble connecting you right now, but I've saved your information. Our team will contact you as soon as possible."
        
        dispatcher.utter_message(text=message)
        return []

    def send_handover_request(self, data: Dict):
        n8n_webhook_url = f"{os.getenv('N8N_WEBHOOK_BASE_URL', 'http://n8n:5678')}/webhook/ev-human-handover"
        
        try:
            response = requests.post(
                n8n_webhook_url,
                json=data,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Error sending handover request to n8n: {e}")
            raise